-- Étend la synchronisation au-delà de la création/édition de transactions :
--
-- 1. Suppressions de transactions : une suppression locale est poussée
--    comme une "pierre tombale" (supprime = true) via le même RPC
--    last-write-wins, pour que les autres appareils la suppriment aussi au
--    prochain pull — une ligne effacée physiquement serait simplement
--    invisible pour eux.
-- 2. Catégories personnalisées (écran Réglages > Catégories), identifiées
--    par leur nom en minuscules (cle) : pas d'id stable entre appareils,
--    et l'app compare déjà les noms sans tenir compte de la casse.
-- 3. Règles de catégorisation apprises, identifiées par
--    cle = match_type || ':' || match_value — l'identité qu'utilise déjà
--    AppDatabase.upsertCategoryRule côté app.
--
-- Chaque table reçoit aussi synced_at, horodatage SERVEUR de la dernière
-- écriture acceptée : le pull filtre et pagine dessus (curseur
-- synced_at + clé), plutôt que sur derniere_modification qui vient de
-- l'horloge de l'appareil émetteur et peut donc être en retard sur le
-- curseur d'un autre appareil.
--
-- À exécuter UNE FOIS, manuellement, via l'éditeur SQL de CHAQUE projet
-- Supabase existant (schema.sql est déjà à jour pour toute nouvelle
-- installation).

-- === Transactions : pierres tombales + curseur serveur ===

alter table public.transactions
  add column supprime boolean not null default false;
alter table public.transactions
  add column synced_at timestamptz not null default now();

create index transactions_user_id_synced_at_idx
  on public.transactions (user_id, synced_at, id);

create or replace function public.sync_upsert_transaction(payload jsonb)
returns public.transactions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.transactions;
  existing_id uuid;
begin
  -- Même transaction opérateur déjà connue du serveur sous un autre uuid
  -- (réinstallation, données effacées, second appareil : le rescan SMS
  -- génère de nouveaux uuid) : on adopte l'id serveur plutôt que de violer
  -- transactions_user_operateur_id_key. Le client détecte l'id différent
  -- dans la ligne retournée et réaligne son id local.
  if payload->>'id_transaction_operateur' is not null then
    select id into existing_id from public.transactions
      where user_id = auth.uid()
        and id_transaction_operateur = payload->>'id_transaction_operateur'
        and id <> (payload->>'id')::uuid;
    if existing_id is not null then
      payload := jsonb_set(payload, '{id}', to_jsonb(existing_id::text));
    end if;
  end if;

  insert into public.transactions (
    id, user_id, source, type, montant, frais, montant_net, solde_apres,
    contact_nom, contact_numero, categorie, date_transaction,
    id_transaction_operateur, sms_brut, notes, statut_edition,
    derniere_modification, supprime
  ) values (
    (payload->>'id')::uuid,
    auth.uid(),
    payload->>'source',
    payload->>'type',
    (payload->>'montant')::numeric,
    coalesce((payload->>'frais')::numeric, 0),
    (payload->>'montant_net')::numeric,
    (payload->>'solde_apres')::numeric,
    payload->>'contact_nom',
    payload->>'contact_numero',
    coalesce(payload->>'categorie', 'Autre'),
    (payload->>'date_transaction')::timestamptz,
    payload->>'id_transaction_operateur',
    payload->>'sms_brut',
    coalesce(payload->>'notes', ''),
    coalesce(payload->>'statut_edition', 'auto'),
    (payload->>'derniere_modification')::timestamptz,
    coalesce((payload->>'supprime')::boolean, false)
  )
  on conflict (id) do update set
    source = excluded.source,
    type = excluded.type,
    montant = excluded.montant,
    frais = excluded.frais,
    montant_net = excluded.montant_net,
    solde_apres = excluded.solde_apres,
    contact_nom = excluded.contact_nom,
    contact_numero = excluded.contact_numero,
    categorie = excluded.categorie,
    date_transaction = excluded.date_transaction,
    id_transaction_operateur = excluded.id_transaction_operateur,
    sms_brut = excluded.sms_brut,
    notes = excluded.notes,
    statut_edition = excluded.statut_edition,
    derniere_modification = excluded.derniere_modification,
    supprime = excluded.supprime,
    synced_at = now()
  where excluded.derniere_modification > public.transactions.derniere_modification
    and public.transactions.user_id = auth.uid()
  returning * into result;

  -- Notre écriture a perdu le conflit (ou la ligne existait déjà à
  -- l'identique) : on retourne la ligne canonique actuelle du serveur.
  -- security definer oblige : on revérifie explicitement user_id ici, pour
  -- qu'une collision d'uuid avec la ligne d'un autre utilisateur ne puisse
  -- jamais être lue en retour (elle resterait simplement bloquée, sans
  -- fuite de données).
  if result.id is null then
    select * into result from public.transactions
      where id = (payload->>'id')::uuid and user_id = auth.uid();
  end if;

  return result;
end;
$$;

revoke all on function public.sync_upsert_transaction(jsonb) from public;
grant execute on function public.sync_upsert_transaction(jsonb) to authenticated;

-- === Catégories ===

create table public.categories (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cle text not null,
  nom text not null,
  supprime boolean not null default false,
  derniere_modification timestamptz not null,
  synced_at timestamptz not null default now(),
  primary key (user_id, cle)
);

create index categories_user_id_synced_at_idx
  on public.categories (user_id, synced_at, cle);

alter table public.categories enable row level security;

-- Lecture seule en direct : toute écriture passe par le RPC ci-dessous,
-- qui applique last-write-wins côté serveur.
create policy "select own categories" on public.categories
  for select using (auth.uid() = user_id);

create or replace function public.sync_upsert_category(payload jsonb)
returns public.categories
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.categories;
  k text := lower(payload->>'nom');
begin
  insert into public.categories (user_id, cle, nom, supprime, derniere_modification)
  values (
    auth.uid(),
    k,
    payload->>'nom',
    coalesce((payload->>'supprime')::boolean, false),
    (payload->>'derniere_modification')::timestamptz
  )
  on conflict (user_id, cle) do update set
    nom = excluded.nom,
    supprime = excluded.supprime,
    derniere_modification = excluded.derniere_modification,
    synced_at = now()
  where excluded.derniere_modification > public.categories.derniere_modification
  returning * into result;

  if result.cle is null then
    select * into result from public.categories
      where user_id = auth.uid() and cle = k;
  end if;

  return result;
end;
$$;

revoke all on function public.sync_upsert_category(jsonb) from public;
grant execute on function public.sync_upsert_category(jsonb) to authenticated;

-- === Règles de catégorisation ===

create table public.category_rules (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  cle text not null,
  match_type text not null,
  match_value text not null,
  categorie text not null,
  supprime boolean not null default false,
  derniere_modification timestamptz not null,
  synced_at timestamptz not null default now(),
  primary key (user_id, cle)
);

create index category_rules_user_id_synced_at_idx
  on public.category_rules (user_id, synced_at, cle);

alter table public.category_rules enable row level security;

create policy "select own category rules" on public.category_rules
  for select using (auth.uid() = user_id);

create or replace function public.sync_upsert_category_rule(payload jsonb)
returns public.category_rules
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.category_rules;
  k text := (payload->>'match_type') || ':' || (payload->>'match_value');
begin
  insert into public.category_rules (
    user_id, cle, match_type, match_value, categorie, supprime, derniere_modification
  ) values (
    auth.uid(),
    k,
    payload->>'match_type',
    payload->>'match_value',
    payload->>'categorie',
    coalesce((payload->>'supprime')::boolean, false),
    (payload->>'derniere_modification')::timestamptz
  )
  on conflict (user_id, cle) do update set
    categorie = excluded.categorie,
    supprime = excluded.supprime,
    derniere_modification = excluded.derniere_modification,
    synced_at = now()
  where excluded.derniere_modification > public.category_rules.derniere_modification
  returning * into result;

  if result.cle is null then
    select * into result from public.category_rules
      where user_id = auth.uid() and cle = k;
  end if;

  return result;
end;
$$;

revoke all on function public.sync_upsert_category_rule(jsonb) from public;
grant execute on function public.sync_upsert_category_rule(jsonb) to authenticated;
