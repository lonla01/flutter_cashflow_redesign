// Extraction de champs de transaction depuis une photo de reçu, via l'API
// vision de Claude (Anthropic). Le client (AddTransactionScreen, voir
// lib/services/receipt_extraction_service.dart) envoie l'image en base64 ;
// cette fonction détient la clé API Anthropic côté serveur (jamais dans
// l'app) et ne fait que relayer l'appel, pour que la clé ne puisse pas
// être extraite de l'APK et utilisée pour facturer le compte du
// propriétaire — même raisonnement que pour la clé de service Supabase.
//
// Authentification : la vérification du JWT Supabase reste activée par
// défaut (ne PAS déployer avec --no-verify-jwt) — seul un utilisateur
// connecté à l'app peut appeler cette fonction, ce qui limite l'abus.
//
// Sortie structurée : on force l'appel d'un outil (tool use) plutôt que de
// demander du JSON en prose — Claude renvoie alors directement un objet
// conforme au schéma, sans risque de texte parasite autour à parser.
//
// Déploiement (à faire manuellement, une fois par projet Supabase — voir
// le document "Git Workflow & Release Process") :
//   supabase functions deploy extract-receipt
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
// Modèle optionnel (défaut : claude-haiku-4-5-20251001) :
//   supabase secrets set ANTHROPIC_MODEL=claude-sonnet-5

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ANTHROPIC_VERSION = '2023-06-01';
const TOOL_NAME = 'record_receipt_fields';

const RECEIPT_TOOL = {
  name: TOOL_NAME,
  description: "Enregistre les champs extraits d'une photo de reçu ou de facture.",
  input_schema: {
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
  },
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { image_base64, mime_type } = await req.json();
    if (!image_base64 || typeof image_base64 !== 'string') {
      return jsonResponse({ error: 'image_base64 manquant' }, 400);
    }
    const mimeType = typeof mime_type === 'string' && mime_type ? mime_type : 'image/jpeg';

    const apiKey = Deno.env.get('ANTHROPIC_API_KEY');
    if (!apiKey) {
      return jsonResponse({ error: 'Clé Anthropic non configurée côté serveur (ANTHROPIC_API_KEY)' }, 500);
    }
    const model = Deno.env.get('ANTHROPIC_MODEL') ?? 'claude-haiku-4-5-20251001';

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': ANTHROPIC_VERSION,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model,
        max_tokens: 1024,
        tools: [RECEIPT_TOOL],
        tool_choice: { type: 'tool', name: TOOL_NAME },
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: { type: 'base64', media_type: mimeType, data: image_base64 },
              },
              {
                type: 'text',
                text:
                  "Analyse cette photo de reçu ou de facture et enregistre les champs extraits via " +
                  `l'outil ${TOOL_NAME}. Si l'image n'est manifestement pas un reçu, mets toutes les ` +
                  'valeurs à null.',
              },
            ],
          },
        ],
      }),
    });

    if (!anthropicResponse.ok) {
      const detail = await anthropicResponse.text();
      console.error('Anthropic error', anthropicResponse.status, detail);
      // Le détail vient du corps d'erreur d'Anthropic (jamais la clé elle-
      // même) : sans risque de le renvoyer au client, utile pour diagnostiquer.
      return jsonResponse(
        { error: `Échec de l'appel au service d'extraction (${anthropicResponse.status}) : ${detail}` },
        502,
      );
    }

    const payload = await anthropicResponse.json();
    const toolUse = (payload.content ?? []).find(
      (block: { type: string }) => block.type === 'tool_use',
    );
    if (!toolUse || typeof toolUse.input !== 'object') {
      console.error('Anthropic: pas de bloc tool_use dans la réponse', JSON.stringify(payload));
      return jsonResponse({ error: "Réponse inattendue du service d'extraction" }, 502);
    }

    return jsonResponse(toolUse.input, 200);
  } catch (e) {
    console.error('extract-receipt error', e);
    return jsonResponse({ error: 'Erreur interne' }, 500);
  }
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
