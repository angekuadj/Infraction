# Configuration Twilio pour SMS et WhatsApp

## Identifiants Twilio configurés

- **Account SID**: `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- **Auth Token**: `your_auth_token_here`
- **Numéro d'envoi**: `+225XXXXXXXXXX`

## Fichier de configuration

Les identifiants sont stockés dans le fichier `.env` à la racine du backend :

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+225XXXXXXXXXX
TWILIO_ENABLED=true
```

⚠️ **Important** : Le fichier `.env` est dans `.gitignore` pour ne pas commiter les secrets.

## Démarrage du backend

### Option 1 : Avec le script de démarrage (recommandé)

```bash
cd backend
./start.sh
```

Ce script charge automatiquement les variables d'environnement depuis `.env`.

### Option 2 : Manuellement

```bash
cd backend
export TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
export TWILIO_AUTH_TOKEN=your_auth_token_here
export TWILIO_PHONE_NUMBER=+225XXXXXXXXXX
export TWILIO_ENABLED=true
mvn spring-boot:run
```

### Option 3 : Avec Docker/Production

Définir les variables d'environnement dans votre configuration Docker ou votre serveur :

```bash
docker run -e TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
           -e TWILIO_AUTH_TOKEN=your_auth_token_here \
           -e TWILIO_PHONE_NUMBER=+225XXXXXXXXXX \
           -e TWILIO_ENABLED=true \
           circulation-api
```

## Fonctionnement des notifications

Lorsqu'un agent valide une infraction (statut "validated" ou "confirmed") :

1. **Recherche du propriétaire** : Le système cherche dans la base de données l'utilisateur dont la plaque correspond
2. **Notification dans l'app** : Une notification est créée dans l'application mobile
3. **SMS** : Un SMS est envoyé au numéro du propriétaire (format +225XXXXXXXXXX)
4. **WhatsApp** : Un message WhatsApp est envoyé avec formatage markdown

### Messages envoyés

**SMS** :
```
CIRCULATION CI: Une infraction concernant votre plaque AB1234CD a été validée. Connectez-vous à l'application pour plus d'informations.
```

**WhatsApp** :
```
🚗 *CIRCULATION CI*

Une infraction concernant votre plaque *AB1234CD* a été validée par la police.

Veuillez consulter l'application pour plus de détails.
```

## Test du système

Pour tester si Twilio fonctionne correctement :

1. Assurez-vous que `TWILIO_ENABLED=true`
2. Lancez le backend
3. Vérifiez les logs pour voir : "Twilio initialisé avec succès"
4. Validez une infraction via l'API ou l'interface admin
5. Vérifiez que le propriétaire reçoit les notifications

## Désactiver les notifications (mode simulation)

Pour désactiver l'envoi réel de SMS/WhatsApp (utile en développement) :

```env
TWILIO_ENABLED=false
```

En mode désactivé, les notifications seront simulées dans les logs mais aucun SMS/WhatsApp ne sera envoyé.

## Dépannage

### Erreur "Twilio non configuré"
- Vérifiez que les variables d'environnement sont bien définies
- Vérifiez que le fichier `.env` existe et est chargé
- Vérifiez que `TWILIO_ENABLED=true`

### Erreur d'envoi SMS
- Vérifiez que le numéro de téléphone du propriétaire est au format +225XXXXXXXXXX
- Vérifiez que votre compte Twilio a des crédits
- Vérifiez que le numéro d'envoi est validé dans votre compte Twilio

### Pas de notification pour une plaque
- Vérifiez qu'un utilisateur existe avec cette plaque dans la base
- Vérifiez que l'utilisateur a un numéro de téléphone enregistré
- Vérifiez que le statut de l'infraction est bien "validated" ou "confirmed"
