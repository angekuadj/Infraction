# Règles du projet Circulation API

## Rôles utilisateurs (8 profils)

1. **User** - Peut s'inscrire (nom, numéro, CNI photo ou numéro, mot de passe)
2. **Proprietaire** - Propriétaire de véhicule
3. **AgentQuipux** - Peut valider ou refuser une infraction
4. **AgentPolice** - Reçoit les signalements validés par l'agent équipu, peut refuser ou valider
5. **ServiceClient** - Répond aux réclamations des utilisateurs, peut clôturer la pile de messages
6. **Admin** - Administrateur système (créé par défaut)
7. **Superviseur** - Accès à tout, peut manager tous les users et profils, contrôler tous les profils
8. **PoliceTerrain** - Police sur le terrain

## Workflow des infractions

1. Signalement initial par un usager (seuls les profils **User**, **Propriétaire** et **Police Terrain** peuvent créer des signalements)
2. L'agent équipu valide ou refuse l'infraction
3. Si validé, l'agent de police reçoit le signalement
4. L'agent de police peut refuser ou valider le signalement
5. **Lors de la validation** : Le propriétaire de la plaque est notifié (notification app + SMS + WhatsApp)

## Restriction d'accès pour l'AgentPolice

- **Agent équipu** : Voit toutes les infractions (statut pending, validated, confirmed, rejected, etc.)
- **Agent de police** : Ne voit que les infractions validées par l'agent équipu (statut "validated" ou "confirmed")
- **Admin/Superviseur** : Voit toutes les infractions

## Verrouillage des signalements

- Les signalements sont automatiquement verrouillés lorsqu'un agent (AgentQuipux ou AgentPolice) ouvre un signalement pour le traiter
- Le verrouillage empêche les autres agents d'accéder ou de modifier le signalement
- Le signalement est déverrouillé lorsque l'agent ferme le détail ou termine le traitement
- Les champs de verrouillage : `lockedBy`, `lockedByUserId`, `lockedAt`
- Endpoints de verrouillage : `POST /api/infractions/{id}/lock` et `POST /api/infractions/{id}/unlock`

## Workflow des réclamations

1. Les utilisateurs créent des réclamations
2. Le service client répond aux réclamations
3. Le service client peut clôturer la pile de messages

## Notifications SMS/WhatsApp

- Le système utilise Twilio pour envoyer des SMS et WhatsApp
- Configuration requise via variables d'environnement :
  - `TWILIO_ACCOUNT_SID` : SID du compte Twilio
  - `TWILIO_AUTH_TOKEN` : Token d'authentification Twilio
  - `TWILIO_PHONE_NUMBER` : Numéro Twilio d'envoi (avec préfixe +225)
  - `TWILIO_ENABLED` : Activer/désactiver l'envoi (false par défaut)
- Lorsqu'une infraction est validée par un agent, le propriétaire de la plaque reçoit :
  - Une notification dans l'application
  - Un SMS au format `+225XXXXXXXXXX`
  - Un message WhatsApp avec formatage markdown
- Recherche du propriétaire : `GET /api/infractions/plate-owner?plaque=AB1234CD` (réservé aux agents)

## Gestion des profils

- **User** : Peut s'inscrire via la route `/api/auth/register` avec (nom, numéro, CNI photo ou numéro, mot de passe)
- **Proprietaire** : Peut s'inscrire via la route `/api/auth/register` avec (nom, prénom, email, téléphone, plaque d'immatriculation, mot de passe, CNI facultatif)
- **Autres profils** : Créés uniquement par l'Admin via une route dédiée
- **Admin par défaut** : `admin@circulation.ci` / `Admin123!`
- **Superviseur** : A accès à tout, peut manager tous les users et profils, contrôler tous les profils

## Gestion des mots de passe

- **Changement de son propre mot de passe** : Tous les utilisateurs connectés peuvent changer leur mot de passe via `/api/auth/change-password` (nécessite l'ancien mot de passe)
- **Modification du mot de passe d'un autre utilisateur** : Réservé aux **Admin** et **Superviseur** via `/api/users/{id}/password`

## Démarrage du projet

```bash
mvn spring-boot:run
```

Le serveur écoute sur `0.0.0.0:8080`.
