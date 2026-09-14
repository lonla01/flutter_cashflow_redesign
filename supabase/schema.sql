-- Phase 2 — schéma cloud Supabase pour mobile_money_tracker.
--
-- Script à exécuter UNE FOIS, manuellement, via l'éditeur SQL du projet
-- Supabase (ou psql avec le mot de passe de la base — jamais embarqué dans
-- l'app). N'est pas consommé par le build Flutter.
--
-- Miroir du modèle local Transaction (voir lib/models/transaction.dart et
-- lib/db/tables.dart), avec Row Level Security : chaque utilisateur ne
-- peut lire/écrire que ses propres transactions.

create table public.transactions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null check (source in ('orange_money','mtn_momo','manuel')),
  type text not null check (type in (
    'transfert_envoye','depot_recu','retrait',
    'paiement_marchand','reception','paiement_service'
  )),
  montant numeric not null,
  frais numeric not null default 0,
  montant_net numeric not null,
  solde_apres numeric,
  contact_nom text,
  contact_numero text,
  categorie text not null default 'Autre',
  date_transaction timestamptz not null,
  id_transaction_operateur text,
  sms_brut text,
  notes text not null default '',
  statut_edition text not null default 'auto'
    check (statut_edition in ('auto','edite_manuellement')),
  derniere_modification timestamptz not null,
  inserted_at timestamptz not null default now()
);

-- Dédup par utilisateur, miroir de l'index partiel local sur
-- id_transaction_operateur (voir lib/db/drift_database.dart).
create unique index transactions_user_operateur_id_key
  on public.transactions (user_id, id_transaction_operateur)
  where id_transaction_operateur is not null;

create index transactions_user_id_derniere_modification_idx
  on public.transactions (user_id, derniere_modification);

-- === Row Level Security ===

alter table public.transactions enable row level security;

create policy "select own transactions" on public.transactions
  for select using (auth.uid() = user_id);

create policy "insert own transactions" on public.transactions
  for insert with check (auth.uid() = user_id);

create policy "update own transactions" on public.transactions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Pas de policy delete : l'app n'a pas de suppression de transaction
-- individuelle exposée aux utilisateurs, donc les suppressions restent
-- refusées par défaut (RLS deny-by-default). À revoir si cette
-- fonctionnalité est ajoutée côté app.

-- === RPC de synchronisation avec résolution de conflit "dernière
-- modification gagne", comparée côté serveur pour éviter toute course ===
--
-- Le client appelle cette fonction avec un instantané JSON de la
-- transaction locale. Elle applique l'upsert seulement si la version
-- envoyée est strictement plus récente que celle déjà en base ; sinon la
-- ligne canonique actuelle est simplement retournée, ce qui permet au
-- client de détecter qu'il a perdu le conflit (voir SyncService._syncOne
-- dans lib/services/sync_service.dart) et de conserver un historique
-- local des deux versions.
create or replace function public.sync_upsert_transaction(payload jsonb)
returns public.transactions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.transactions;
begin
  insert into public.transactions (
    id, user_id, source, type, montant, frais, montant_net, solde_apres,
    contact_nom, contact_numero, categorie, date_transaction,
    id_transaction_operateur, sms_brut, notes, statut_edition, derniere_modification
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
    (payload->>'derniere_modification')::timestamptz
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
    derniere_modification = excluded.derniere_modification
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
