// Extraction de champs de transaction depuis une photo de reçu, via
// l'API vision d'OpenAI. Le client (AddTransactionScreen, voir
// lib/services/receipt_extraction_service.dart) envoie l'image en base64 ;
// cette fonction détient la clé API OpenAI côté serveur (jamais dans
// l'app) et ne fait que relayer l'appel, pour que la clé ne puisse pas
// être extraite de l'APK et utilisée pour facturer le compte du
// propriétaire — même raisonnement que pour la clé de service Supabase.
//
// Authentification : la vérification du JWT Supabase reste activée par
// défaut (ne PAS déployer avec --no-verify-jwt) — seul un utilisateur
// connecté à l'app peut appeler cette fonction, ce qui limite l'abus.
//
// Déploiement (à faire manuellement, une fois par projet Supabase — voir
// le document "Git Workflow & Release Process") :
//   supabase functions deploy extract-receipt
//   supabase secrets set OPENAI_API_KEY=sk-...
// Modèle optionnel (défaut : gpt-4o-mini) :
//   supabase secrets set OPENAI_MODEL=gpt-4o

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ExtractedFields {
  montant: number | null;
  marchand: string | null;
  date: string | null; // "YYYY-MM-DD"
  notes: string | null;
}

const SYSTEM_PROMPT = `Tu extrais les informations d'un reçu ou d'une facture à partir d'une photo.
Réponds UNIQUEMENT avec un objet JSON strict de cette forme, sans texte autour :
{
  "montant": <nombre, le montant total payé, sans symbole de devise, ou null si illisible>,
  "marchand": <chaîne, le nom du commerce/marchand, ou null si illisible>,
  "date": <chaîne "YYYY-MM-DD", la date du reçu, ou null si illisible>,
  "notes": <chaîne courte décrivant l'achat (ex: articles principaux), ou null>
}
Si l'image n'est manifestement pas un reçu, renvoie toutes les valeurs à null.`;

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

    const apiKey = Deno.env.get('OPENAI_API_KEY');
    if (!apiKey) {
      return jsonResponse({ error: "Clé OpenAI non configurée côté serveur (OPENAI_API_KEY)" }, 500);
    }
    const model = Deno.env.get('OPENAI_MODEL') ?? 'gpt-4o-mini';

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          {
            role: 'user',
            content: [
              { type: 'text', text: 'Extrait les champs de ce reçu au format JSON demandé.' },
              { type: 'image_url', image_url: { url: `data:${mimeType};base64,${image_base64}` } },
            ],
          },
        ],
      }),
    });

    if (!openaiResponse.ok) {
      const detail = await openaiResponse.text();
      console.error('OpenAI error', openaiResponse.status, detail);
      return jsonResponse({ error: "Échec de l'appel au service d'extraction" }, 502);
    }

    const payload = await openaiResponse.json();
    const content = payload.choices?.[0]?.message?.content;
    if (typeof content !== 'string') {
      return jsonResponse({ error: 'Réponse inattendue du service d\'extraction' }, 502);
    }

    let fields: ExtractedFields;
    try {
      fields = JSON.parse(content);
    } catch {
      return jsonResponse({ error: "Réponse du service d'extraction illisible" }, 502);
    }

    return jsonResponse(fields, 200);
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
