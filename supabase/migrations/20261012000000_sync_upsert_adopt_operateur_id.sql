-- Corrige "duplicate key value violates unique constraint
-- transactions_user_operateur_id_key" à la synchronisation : quand une
-- transaction locale porte un uuid différent de celui déjà en base pour le
-- même id_transaction_operateur (réinstallation, données de l'app
-- effacées, changement de bundle id, second appareil — le rescan SMS
-- génère de nouveaux uuid), sync_upsert_transaction adopte désormais l'id
-- serveur au lieu de tenter un insert en doublon. Le client réaligne son
-- id local sur celui retourné (voir SyncService._syncOne).
--
-- À exécuter UNE FOIS, manuellement, via l'éditeur SQL de CHAQUE projet
-- Supabase existant (schema.sql est déjà à jour pour toute nouvelle
-- installation).

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
