// Extraction de champs de transaction depuis une photo de reçu, via l'un
// de plusieurs fournisseurs IA au choix de l'utilisateur (voir Réglages >
// Modèle IA dans l'app, lib/screens/ai_model_screen.dart). Le client
// envoie l'image en base64 et un `model_id` de la forme
// "<fournisseur>:<modèle>" (ex. "anthropic:claude-sonnet-5",
// "openrouter:qwen/qwen2.5-vl-72b-instruct") ; cette fonction détient
// toutes les clés API côté serveur (jamais dans l'app) et route vers le
// bon fournisseur, pour qu'aucune clé ne puisse être extraite de l'APK et
// utilisée pour facturer le compte du propriétaire — même raisonnement
// que pour la clé de service Supabase.
//
// Authentification : la vérification du JWT Supabase reste activée par
// défaut (ne PAS déployer avec --no-verify-jwt) — seul un utilisateur
// connecté à l'app peut appeler cette fonction.
//
// Chaque essai (succès ou échec) est journalisé dans
// receipt_scan_logs avec le JWT de l'appelant (jamais le service role),
// pour comparer les modèles en performance/latence réelles — voir la
// migration 20260916000000_add_receipt_scan_logs.sql. Un échec de
// journalisation ne fait jamais échouer la requête elle-même.
//
// Déploiement (à faire manuellement, une fois par projet Supabase — voir
// le document "Git Workflow & Release Process") :
//   supabase functions deploy extract-receipt
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//   supabase secrets set OPENAI_API_KEY=sk-...
//   supabase secrets set OPENROUTER_API_KEY=sk-or-...
//   supabase secrets set GOOGLE_API_KEY=...
// (SUPABASE_URL et SUPABASE_ANON_KEY sont déjà injectées automatiquement
// par la plateforme — jamais à définir manuellement.)

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ANTHROPIC_VERSION = '2023-06-01';
const TOOL_NAME = 'record_receipt_fields';
const DEFAULT_MODEL_ID = 'anthropic:claude-sonnet-5';

const EXTRACTION_PROMPT =
  "Analyse cette photo de reçu ou de facture et enregistre les champs extraits via l'outil " +
  `${TOOL_NAME}. Si l'image n'est manifestement pas un reçu, mets toutes les valeurs à null.`;

// Schéma JSON Schema (dialecte OpenAI/Anthropic — types ["x","null"] pour
// l'optionnalité) partagé par Anthropic, OpenAI et OpenRouter.
const JSON_SCHEMA_TOOL = {
  type: 'object',
  properties: {
    montant: {
      type: ['number', 'null'],
      description: 'Montant total payé, en nombre, sans symbole de devise. null si illisible.',
    },
    marchand: {
      type: ['string', 'null'],
      description: 'Nom du commerce/marchand. null si illisible.',
    },
    date: {
      type: ['string', 'null'],
      description: 'Date du reçu au format "YYYY-MM-DD". null si illisible.',
    },
    notes: {
      type: ['string', 'null'],
      description: "Courte description de l'achat (ex: articles principaux). null si non pertinent.",
    },
  },
  required: ['montant', 'marchand', 'date', 'notes'],
};

// Dialecte de schéma propre à Gemini (sous-ensemble OpenAPI : types en
// MAJUSCULES, `nullable` plutôt qu'un type union).
const GEMINI_SCHEMA = {
  type: 'OBJECT',
  properties: {
    montant: { type: 'NUMBER', nullable: true, description: JSON_SCHEMA_TOOL.properties.montant.description },
    marchand: { type: 'STRING', nullable: true, description: JSON_SCHEMA_TOOL.properties.marchand.description },
    date: { type: 'STRING', nullable: true, description: JSON_SCHEMA_TOOL.properties.date.description },
    notes: { type: 'STRING', nullable: true, description: JSON_SCHEMA_TOOL.properties.notes.description },
  },
  required: ['montant', 'marchand', 'date', 'notes'],
};

interface ExtractedFields {
  montant: number | null;
  marchand: string | null;
  date: string | null; // "YYYY-MM-DD"
  notes: string | null;
}

class ProviderError extends Error {
  status: number;
  constructor(message: string, status = 502) {
    super(message);
    this.status = status;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const startedAt = Date.now();
  let modelId = DEFAULT_MODEL_ID;

  try {
    const { image_base64, mime_type, model_id } = await req.json();
    if (!image_base64 || typeof image_base64 !== 'string') {
      return jsonResponse({ error: 'image_base64 manquant' }, 400);
    }
    const mimeType = typeof mime_type === 'string' && mime_type ? mime_type : 'image/jpeg';
    modelId = typeof model_id === 'string' && model_id ? model_id : DEFAULT_MODEL_ID;

    const separator = modelId.indexOf(':');
    if (separator < 0) {
      return jsonResponse({ error: `model_id invalide: ${modelId}` }, 400);
    }
    const provider = modelId.slice(0, separator);
    const model = modelId.slice(separator + 1);

    let fields: ExtractedFields;
    switch (provider) {
      case 'anthropic':
        fields = await callAnthropic(model, image_base64, mimeType);
        break;
      case 'openai':
        fields = await callOpenAiCompatible({
          baseUrl: 'https://api.openai.com/v1/chat/completions',
          apiKey: Deno.env.get('OPENAI_API_KEY'),
          apiKeyName: 'OPENAI_API_KEY',
          model,
          imageB64: image_base64,
          mimeType,
          providerLabel: 'OpenAI',
        });
        break;
      case 'openrouter':
        fields = await callOpenAiCompatible({
          baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
          apiKey: Deno.env.get('OPENROUTER_API_KEY'),
          apiKeyName: 'OPENROUTER_API_KEY',
          model,
          imageB64: image_base64,
          mimeType,
          providerLabel: 'OpenRouter',
          extraHeaders: {
            'HTTP-Referer': 'https://github.com/lonla01/flutter_cashflow_redesign',
            'X-Title': 'Mobile Money Tracker',
          },
        });
        break;
      case 'google':
        fields = await callGemini(model, image_base64, mimeType);
        break;
      default:
        return jsonResponse({ error: `Fournisseur inconnu: ${provider}` }, 400);
    }

    await logScan(req, modelId, true, null, Date.now() - startedAt);
    return jsonResponse(fields, 200);
  } catch (e) {
    const status = e instanceof ProviderError ? e.status : 500;
    const message = e instanceof ProviderError ? e.message : 'Erreur interne';
    if (!(e instanceof ProviderError)) console.error('extract-receipt error', e);
    await logScan(req, modelId, false, message, Date.now() - startedAt);
    return jsonResponse({ error: message }, status);
  }
});

async function callAnthropic(model: string, imageB64: string, mimeType: string): Promise<ExtractedFields> {
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY');
  if (!apiKey) throw new ProviderError('Clé Anthropic non configurée côté serveur (ANTHROPIC_API_KEY)', 500);
  const resolvedModel = model || Deno.env.get('ANTHROPIC_MODEL') || 'claude-haiku-4-5-20251001';

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': ANTHROPIC_VERSION,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: resolvedModel,
      max_tokens: 1024,
      tools: [
        {
          name: TOOL_NAME,
          description: "Enregistre les champs extraits d'une photo de reçu ou de facture.",
          input_schema: JSON_SCHEMA_TOOL,
        },
      ],
      tool_choice: { type: 'tool', name: TOOL_NAME },
      messages: [
        {
          role: 'user',
          content: [
            { type: 'image', source: { type: 'base64', media_type: mimeType, data: imageB64 } },
            { type: 'text', text: EXTRACTION_PROMPT },
          ],
        },
      ],
    }),
  });
  if (!res.ok) throw await providerError('Anthropic', res);

  const payload = await res.json();
  const toolUse = (payload.content ?? []).find((b: { type: string }) => b.type === 'tool_use');
  if (!toolUse || typeof toolUse.input !== 'object') {
    console.error('Anthropic: pas de bloc tool_use', JSON.stringify(payload));
    throw new ProviderError("Réponse inattendue du service d'extraction (Anthropic)");
  }
  return toolUse.input as ExtractedFields;
}

async function callOpenAiCompatible(opts: {
  baseUrl: string;
  apiKey: string | undefined;
  apiKeyName: string;
  model: string;
  imageB64: string;
  mimeType: string;
  providerLabel: string;
  extraHeaders?: Record<string, string>;
}): Promise<ExtractedFields> {
  const { baseUrl, apiKey, apiKeyName, model, imageB64, mimeType, providerLabel, extraHeaders } = opts;
  if (!apiKey) throw new ProviderError(`Clé ${providerLabel} non configurée côté serveur (${apiKeyName})`, 500);
  if (!model) throw new ProviderError(`model_id incomplet pour ${providerLabel}`, 400);

  const res = await fetch(baseUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      ...(extraHeaders ?? {}),
    },
    body: JSON.stringify({
      model,
      tools: [
        {
          type: 'function',
          function: {
            name: TOOL_NAME,
            description: "Enregistre les champs extraits d'une photo de reçu ou de facture.",
            parameters: JSON_SCHEMA_TOOL,
          },
        },
      ],
      tool_choice: { type: 'function', function: { name: TOOL_NAME } },
      messages: [
        { role: 'system', content: "Tu extrais les informations d'un reçu ou d'une facture à partir d'une photo." },
        {
          role: 'user',
          content: [
            { type: 'text', text: EXTRACTION_PROMPT },
            { type: 'image_url', image_url: { url: `data:${mimeType};base64,${imageB64}` } },
          ],
        },
      ],
    }),
  });
  if (!res.ok) throw await providerError(providerLabel, res);

  const payload = await res.json();
  const toolCall = payload.choices?.[0]?.message?.tool_calls?.[0];
  if (!toolCall?.function?.arguments) {
    console.error(`${providerLabel}: pas de tool_call`, JSON.stringify(payload));
    throw new ProviderError(`Réponse inattendue du service d'extraction (${providerLabel})`);
  }
  try {
    return JSON.parse(toolCall.function.arguments) as ExtractedFields;
  } catch {
    throw new ProviderError(`Réponse JSON illisible (${providerLabel})`);
  }
}

async function callGemini(model: string, imageB64: string, mimeType: string): Promise<ExtractedFields> {
  const apiKey = Deno.env.get('GOOGLE_API_KEY');
  if (!apiKey) throw new ProviderError('Clé Google non configurée côté serveur (GOOGLE_API_KEY)', 500);
  const resolvedModel = model || 'gemini-2.5-flash';

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${resolvedModel}:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: EXTRACTION_PROMPT },
              { inline_data: { mime_type: mimeType, data: imageB64 } },
            ],
          },
        ],
        generationConfig: {
          response_mime_type: 'application/json',
          response_schema: GEMINI_SCHEMA,
        },
      }),
    },
  );
  if (!res.ok) throw await providerError('Google', res);

  const payload = await res.json();
  const text = payload.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof text !== 'string') {
    console.error('Google: pas de texte de réponse', JSON.stringify(payload));
    throw new ProviderError("Réponse inattendue du service d'extraction (Google)");
  }
  try {
    return JSON.parse(text) as ExtractedFields;
  } catch {
    throw new ProviderError('Réponse JSON illisible (Google)');
  }
}

async function providerError(providerLabel: string, res: Response): Promise<ProviderError> {
  const detail = await res.text();
  console.error(`${providerLabel} error`, res.status, detail);
  return new ProviderError(
    `Échec de l'appel au service d'extraction (${providerLabel}, ${res.status}) : ${detail}`,
    502,
  );
}

/// Journalise l'essai avec le JWT de l'appelant (jamais le service role),
/// pour que RLS s'applique normalement. N'importe quelle erreur ici est
/// avalée : un journal en panne ne doit jamais faire échouer une
/// extraction par ailleurs réussie.
async function logScan(
  req: Request,
  modelId: string,
  success: boolean,
  errorMessage: string | null,
  latencyMs: number,
): Promise<void> {
  try {
    const authHeader = req.headers.get('Authorization');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    if (!authHeader || !supabaseUrl || !anonKey) return;

    await fetch(`${supabaseUrl}/rest/v1/receipt_scan_logs`, {
      method: 'POST',
      headers: {
        Authorization: authHeader,
        apikey: anonKey,
        'Content-Type': 'application/json',
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({
        model_id: modelId,
        success,
        error_message: errorMessage,
        latency_ms: latencyMs,
      }),
    });
  } catch (e) {
    console.error('logScan error', e);
  }
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
