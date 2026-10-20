# Circulation API (backend Spring Boot)

Backend Java Spring Boot répondant à toutes les exigences de l'application mobile
Flutter `circulation` (`net.circulation.ci.circulation`).

## Stack

- Java 21, Spring Boot 3.5.7 (Web, Security, Data JPA, Validation)
- JWT (jjwt 0.12.3) — authentification stateless `Bearer`
- H2 en mémoire par défaut, PostgreSQL supporté via variables d'environnement
- Stockage fichiers vidéo/photo sur disque (`uploads/`), servis sur `/uploads/**`

## Démarrage

```bash
cd backend
mvn spring-boot:run
```

Le serveur écoute sur `0.0.0.0:8080` (accessible depuis l'émulateur Android via `http://10.0.2.2:8080`).

Compte administrateur créé au démarrage : `admin@circulation.ci` / `Admin123!`
(surchargeable via `APP_ADMIN_EMAIL` / `APP_ADMIN_PASSWORD`).

### PostgreSQL (production)

```bash
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/circulation
export SPRING_DATASOURCE_USERNAME=circulation
export SPRING_DATASOURCE_PASSWORD=secret
export SPRING_DATASOURCE_DRIVER=org.postgresql.Driver
export APP_JWT_SECRET=une-cle-longue-et-aleatoire
mvn spring-boot:run
```

## Rôles

`usager` (plaque obligatoire), `client` (téléphone), `agent` (matricule), `admin`.
Les valeurs API `usager`, `client`, `agent`, `admin` sont renvoyées telles quelles.
Un rôle inconnu retourne `400` avec `code=ROLE_NOT_ALLOWED`.

## Routes implémentées

### Auth — `/api/auth`
| Méthode | Route | Description |
|---|---|---|
| POST | `/api/auth/login` | `{identifier,email,phone,password}` → `{token,accessToken,user,data}` |
| POST | `/api/auth/register` | `{nom,prenom,email,phone,password,role,plaqueImmatriculation,matricule}` |
| GET | `/api/auth/me` | Profil courant (JWT) |
| POST | `/api/auth/plaque` | Met à jour la plaque |
| POST | `/api/auth/activate-client` | Passe le compte en rôle `client` (+ téléphone optionnel) |
| POST | `/api/auth/panne` | `{start,end}` → `enPanne=true` |

### Types d'incivisme — `/api/infraction-types`
- GET `/api/infraction-types` → `{data:[...], types:[...]}` (10 types seedés)

### Signalements — `/api/infractions`
| Méthode | Route | Description |
|---|---|---|
| GET | `/api/infractions` | Liste (filtrée selon le rôle) |
| GET | `/api/infractions/for-my-plate?plaque=` | Signalements liés à une plaque |
| GET | `/api/infractions/{id}` | Détail |
| POST | `/api/infractions` | **JSON** ou **multipart** (`video`, `photo`, `plate`, `image` + champs) |
| DELETE | `/api/infractions/{id}` | Suppression |

Les fichiers uploadés sont renvoyés via `videoUrl`/`imageUrl` (`http://host/uploads/<nom>`).

### Notifications — `/api/notifications`
- GET `/api/notifications?unreadOnly=`
- POST `/api/notifications/read-all`
- POST `/api/notifications/{id}/read`
- GET `/api/notifications/{id}`

### Support / Réclamations — `/api/support`
- GET `/api/support`, `/api/support/queue`, `/api/support/assigned`, `/api/support/reclamations`
- POST `/api/support/reclamations` `{subject,message}`
- GET `/api/support/reclamations/{id}`
- GET/POST `/api/support/reclamations/{id}/messages`
- POST `/api/support/reclamations/{id}/close`

### Portefeuille — `/api/wallet`
- GET `/api/wallet` → `{data:{solde,amount,balance,operations:[...]}}`

## Format d'erreur

```json
{
  "message": "...",
  "error": "...",
  "code": "BAD_REQUEST|UNAUTHORIZED|FORBIDDEN|NOT_FOUND|CONFLICT|ROLE_NOT_ALLOWED|INTERNAL_ERROR|ENDPOINT_NOT_FOUND",
  "statusCode": 400,
  "timestamp": "..."
}
```
