-- Ajoute 'manuel' aux valeurs autorisées de transactions.source, pour les
-- transactions saisies à la main (formulaire libre ou photo de reçu) plutôt
-- que détectées dans un SMS d'opérateur — voir AddTransactionScreen côté
-- app et sourceToString/sourceFromString dans lib/models/transaction.dart.
--
-- À exécuter UNE FOIS, manuellement, via l'éditeur SQL de CHAQUE projet
-- Supabase déjà créé avec l'ancienne contrainte (schema.sql a été mis à
-- jour pour toute nouvelle installation, mais un projet existant doit
-- recevoir ce correctif séparément). Suivre l'application dans le
-- changelog de schéma (voir le document "Git Workflow & Release Process").
--
-- Le nom de contrainte ci-dessous est celui que Postgres génère
-- automatiquement pour une contrainte check non nommée sur cette colonne
-- (<table>_<colonne>_check) : à vérifier dans le dashboard (Database >
-- Tables > transactions > Constraints) si cette migration échoue.

alter table public.transactions drop constraint if exists transactions_source_check;
alter table public.transactions add constraint transactions_source_check
  check (source in ('orange_money', 'mtn_momo', 'manuel'));
