-- Journal des essais d'extraction de reçu, un par appel (succès ou échec),
-- pour pouvoir comparer les modèles IA du picker (Réglages > Modèle IA) en
-- performance/latence/fiabilité — pas seulement en coût théorique. Écrit
-- par la fonction Edge extract-receipt avec le JWT de l'appelant (jamais
-- le service role), donc RLS s'applique normalement : chaque utilisateur
-- ne voit que ses propres essais.
--
-- À exécuter UNE FOIS, manuellement, via l'éditeur SQL de chaque projet
-- Supabase (ou `supabase db push` si le projet est lié en CLI).

create table public.receipt_scan_logs (
  id uuid primary key default gen_random_uuid(),
  -- default auth.uid() : la fonction Edge insère via un simple POST REST
  -- avec le JWT de l'appelant transmis tel quel (Authorization: Bearer
  -- <jwt utilisateur>), sans décoder le JWT elle-même ni passer user_id
  -- explicitement — Postgres le déduit de la session JWT comme le fait le
  -- client Supabase habituel.
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  model_id text not null,
  success boolean not null,
  error_message text,
  latency_ms integer,
  created_at timestamptz not null default now()
);

create index receipt_scan_logs_user_id_created_at_idx
  on public.receipt_scan_logs (user_id, created_at desc);

alter table public.receipt_scan_logs enable row level security;

create policy "select own scan logs" on public.receipt_scan_logs
  for select using (auth.uid() = user_id);

create policy "insert own scan logs" on public.receipt_scan_logs
  for insert with check (auth.uid() = user_id);

-- Pas de update/delete exposés : c'est un journal, jamais modifié après
-- écriture (RLS deny-by-default couvre ces deux opérations).
