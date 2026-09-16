# AI Model Assessment — Receipt Scanning

_Compiled: 2026-09-16_

Cost and vision/OCR-performance comparison across providers, done while choosing the
model pool for the receipt-scanning feature (Settings > Modèle IA). Kept for future
reference — e.g. if the pool needs revisiting, or pricing/models shift again.

## Methodology

- **Est. $/scan** assumes ~1500 input tokens (a resized receipt photo + short prompt)
  and ~150 output tokens (the small JSON result) per scan — the same assumption
  applied to every model so the comparison is apples-to-apples. Actual image
  tokenization formulas differ slightly by provider, so treat this as directional,
  not exact.
- **Cost score** is a log-scaled 1–100 (1 = cheapest paid option in the set, 100 =
  priciest), so a 10x cost difference reads as a consistent visual gap rather than
  compressing at one end. The free tier is called out separately.
- **Vision/doc performance** is a *qualitative* tier (Fair / Good / Very good /
  Excellent), not a verified benchmark score — a clean, apples-to-apples numeric
  benchmark across this exact model set wasn't available (OCR Arena's live
  leaderboard is JS-rendered and didn't return data via fetch; general web search
  surfaced scores for adjacent model generations — Opus 4.7, GPT-5.5, Gemini 3 — not
  exact matches). Built from what could actually be confirmed: Qwen3-VL's technical
  report explicitly names OCRBench/OmniDocBench/CC-OCR as design targets; OCR Arena's
  scene-text leaderboard clustered GPT-5-mini and Gemini 2.5 Flash within ~22 ELO of
  each other; Qwen2.5-VL-72B has a confirmed 88.8% OCRBench score; and Claude
  Haiku 4.5's "Fair" rating reflects real in-app testing (it underperformed for this
  task), not a guess.

## Full comparison

| Provider | Model | Est. $/scan | Cost score | Vision/doc performance (qualitative) |
|---|---|---|---|---|
| Google (OpenRouter) | Gemma 4 26B A4B (free) | $0 | Free | Fair — small, general-purpose, not OCR-specialized |
| Google (OpenRouter) | Gemma 3 4B | $0.00009 | 1 | Fair — same caveat, smallest of the line |
| OpenAI | gpt-5-nano | $0.000135 | 8 | Fair — smallest GPT-5 tier, expect more errors on messy layouts |
| Google (OpenRouter) | Gemma 3 27B | $0.000144 | 9 | Good — solid general vision, not doc-specialized |
| Google (OpenRouter) | Gemma 4 31B | $0.000186 | 14 | Good — newest Gemma gen, same caveat |
| Google (direct) | Gemini 2.5 Flash-Lite | $0.00021 | 16 | Good — lighter sibling of a model that tests well on OCR |
| Qwen (OpenRouter) | Qwen3 VL 8B Instruct | $0.000244 | 18 | Good — smallest of an OCR-specialized family |
| **Qwen (OpenRouter)** | **Qwen3 VL 30B A3B Instruct** | $0.000273 | 20 | Very good — mid-size, inherits OCR-focused training |
| OpenAI | gpt-4o-mini | $0.000315 | 22 | Fair — older/smaller, generally trails gpt-5-mini on vision |
| DeepSeek | deepseek-flash (off-peak) | $0.000315 | 22 | Fair — vision is secondary to this model's text/reasoning focus |
| Qwen (OpenRouter) | Qwen3 VL 235B A22B Instruct | $0.000432 | 28 | **Excellent** — flagship of a family explicitly built for OCR/document benchmarks |
| DeepSeek | deepseek-flash (peak) | $0.00063 | 35 | Fair — same as off-peak, just pricier hours |
| **OpenAI** | **gpt-5-mini** | $0.000675 | 36 | Very good — confirmed competitive on OCR-specific leaderboard |
| **Google (direct)** | **Gemini 2.5 Flash*** | $0.000825 | 40 | Very good — confirmed competitive on OCR-specific leaderboard |
| **Qwen (OpenRouter)** | **Qwen2.5-VL 72B Instruct** | $0.00135 | 49 | Very good — confirmed 88.8% OCRBench (real measured number) |
| Anthropic | claude-haiku-4.5 | $0.00225 | 58 | **Fair — tested in-app: not up to the task** |
| **OpenAI** | **gpt-5** | $0.003375 | 65 | Excellent — flagship tier, strong on document benchmarks generally |
| **Anthropic** | **claude-sonnet-5** | $0.0045 | 70 | Very good — Anthropic's mid tier |
| Anthropic | claude-opus-5 | $0.01125 | 87 | Excellent — flagship reasoning + vision |
| Anthropic | claude-fable-5-1 | $0.0225 | 100 | Excellent — top of the line, likely overkill for a receipt |

\* Selected for the picker on 2026-09-14; swapped to **gemini-3.8-flash** on
2026-09-16 after `gemini-2.5-flash` appeared to be aging out of current Google docs.
Cost/performance figures above are for `gemini-2.5-flash` and weren't re-measured for
`gemini-3.8-flash`.

## Selected for the picker (Settings > Modèle IA)

Bolded rows above — 6 models spanning 4 provider integrations (Anthropic, OpenAI,
OpenRouter, Google direct):

1. Claude Sonnet 5 (`anthropic:claude-sonnet-5`)
2. GPT-5 (`openai:gpt-5`)
3. GPT-5 mini (`openai:gpt-5-mini`)
4. Qwen2.5-VL 72B Instruct (`openrouter:qwen/qwen2.5-vl-72b-instruct`)
5. Qwen3-VL 30B A3B Instruct (`openrouter:qwen/qwen3-vl-30b-a3b-instruct`)
6. Gemini 3.8 Flash (`google:gemini-3.8-flash`, originally Gemini 2.5 Flash)

Every scan is logged to `receipt_scan_logs` (model, latency, success/error) — see the
Edge Function `supabase/functions/extract-receipt/index.ts` — so this qualitative
assessment can eventually be checked against real usage data.

## Sources

- [Qwen3-VL Technical Report](https://arxiv.org/pdf/2511.21631)
- [Multimodal AI Benchmarks 2026: Vision, Audio, Code](https://www.digitalapplied.com/blog/multimodal-ai-benchmarks-2026-vision-audio-code)
- [OCR Arena — Gemini 2.5 Flash vs Gemini 2.5 Pro](https://www.ocrarena.ai/compare/gemini-2-5-flash/gemini-2-5-pro)
- Anthropic pricing: Claude API skill reference (cached 2026-06-24)
- OpenAI pricing: `developers.openai.com/api/docs/pricing`
- DeepSeek pricing: `api-docs.deepseek.com/quick_start/pricing`
- Gemini pricing: `ai.google.dev/gemini-api/docs/pricing`
- Qwen/Gemma (OpenRouter) pricing: `openrouter.ai/qwen`, `openrouter.ai/google`
