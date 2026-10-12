# Import des SMS Mobile Money sur iOS (via Raccourci)

iOS n'offre à aucune app tierce — même avec une review manuelle, même en
entreprise/MDM — d'API pour lire le contenu des SMS. C'est une restriction
plateforme volontaire (anti-spyware), pas un oubli, et il n'existe aucun
contournement légitime sans jailbreak. Contrairement à Android
(`lib/parsing/sms_listener.dart`), il n'y a donc pas d'écoute automatique
possible sur iOS.

À la place, l'utilisateur déclenche lui-même un **Raccourci (Shortcuts)**
qui sélectionne les SMS Orange Money / MTN MoMo pertinents et les transmet
à l'app par deep link. L'app les traite ensuite avec exactement le même
moteur de parsing et la même dé-duplication que le chemin Android (voir
`lib/services/sms_import_link_service.dart`), donc relancer le Raccourci
plusieurs fois ne crée jamais de doublons.

## Contrat du lien

```
mobilemoneytracker://import-sms?bodies=<texte encodé URL>
```

- `bodies` contient un ou plusieurs corps de SMS, séparés par le texte
  littéral `\n<<<SMS>>>\n` (voir `SmsImportLinkService.separateur`).
- Le `?bodies=...` entier doit être encodé URL (action **Encoder l'URL**
  dans Shortcuts) avant d'être collé dans l'URL finale.
- Le même schéma `mobilemoneytracker://` sert aussi au lien de confirmation
  d'email Supabase (`login-callback`, voir `supabase_config.dart`) — les
  deux cohabitent sans conflit, `SmsImportLinkService` ignore tout lien dont
  l'hôte n'est pas `import-sms`.

## Construire le Raccourci "Importer mes SMS Mobile Money"

Dans l'app **Raccourcis** (Shortcuts), créer un nouveau raccourci avec ces
actions, dans l'ordre :

1. **Rechercher des messages où** (`Find Messages where`)
   - Condition : `Expéditeur contient` → `Orange Money` (ajuster selon le
     sender ID réel observé sur le terrain, voir
     `SmsListenerService.expediteursSuivis` côté Android pour la liste)
   - Filtre additionnel conseillé : `Date est aujourd'hui` (ou "7 derniers
     jours" pour un rattrapage plus large) — garde le lien court et évite de
     re-signaler les mêmes vieux SMS à chaque lancement.
   - Trier par date, le plus récent en dernier.

2. **Rechercher des messages où** (deuxième bloc, car Shortcuts ne permet
   qu'un seul groupe de conditions OU par action)
   - Condition : `Expéditeur contient` → `MTN`
   - Mêmes filtres de date que l'étape 1.

3. **Combiner les listes** (`Combine Lists`) — fusionne les résultats des
   deux étapes précédentes en une seule liste de messages.

4. **Répéter pour chaque élément** (`Repeat with Each`) sur la liste
   combinée :
   - À l'intérieur de la boucle : **Texte** (`Text`) contenant le
     `Contenu` (Content) du message courant.
   - **Ajouter à la variable** (`Add to Variable`) → variable `Corps SMS`
     (créée à la première itération).

5. **Combiner le texte** (`Combine Text`) sur la variable `Corps SMS`,
   séparateur **Personnalisé** → coller exactement `\n<<<SMS>>>\n` (trois
   chevrons de chaque côté, retours à la ligne avant/après).

6. **Encoder l'URL** (`URL Encode`) sur le résultat de l'étape 5.

7. **Texte** (`Text`) : `mobilemoneytracker://import-sms?bodies=` suivi
   immédiatement (sans espace) du résultat de l'étape 6.

8. **Ouvrir les URLs** (`Open URLs`) sur le texte de l'étape 7.

Renommer le raccourci (ex. "Importer mes SMS Mobile Money"), lui donner une
icône, et l'ajouter à l'écran d'accueil pour un import en un tap — c'est
l'équivalent du bouton "Rescanner les SMS" des Réglages côté Android, en
un peu moins automatique (déclenché par l'utilisateur plutôt qu'en tâche de
fond), ce qui est la limite dure de la plateforme iOS.

### Première exécution

iOS demandera l'autorisation d'accès de Shortcuts aux Messages lors de la
première utilisation de l'action "Rechercher des messages" — c'est normal,
à accepter une seule fois.

### Limite pratique

Pour un très grand nombre de SMS d'un coup (ex. premier import d'un
historique de plusieurs mois), le lien `bodies=` peut devenir long. Si
`Open URLs` échoue silencieusement sur un très gros lot, resserrer le
filtre de date (ex. "7 derniers jours" au lieu de "tout l'historique") ou
lancer le Raccourci plusieurs fois avec des plages de dates plus courtes —
la dé-duplication côté app rend ça sans risque.
