# Circulation Admin (Angular)

Interface web d'administration pour l'application mobile `circulation`, connectée au
backend Spring Boot (`../backend`).

## Stack

- Angular 21 (standalone components, signals, routing lazy-loaded)
- `provideHttpClient` + intercepteur JWT fonctionnel
- Guards `authGuard` / `guestGuard` / `managerGuard`
- SCSS design system (thème clair + sidebar navy), sans dépendance UI externe
- Composant `<app-icon>` SVG maison, aucun composant tiers

## Démarrage

Le backend doit tourner sur `http://localhost:8080`. Le dev-server proxifie
`/api` et `/uploads` vers le backend (`proxy.conf.json`), donc `apiBaseUrl` est vide.

```bash
npm install
npm start          # http://localhost:4200
```

Build de production :

```bash
npm run build      # -> dist/web-admin
```

> Environnement : `NodeOptions=--tls-max-v1.2` peut être nécessaire si le réseau
> réinitialise les connexions TLS 1.3 de Node (`.npmrc` déjà configuré).

## Profils

8 profils. Seul le profil **Utilisateur** peut s'inscrire publiquement ; tous les
autres sont créés par un administrateur ou un superviseur.

| Code | Libellé | Création | Capacités |
|---|---|---|---|
| `user` | Utilisateur | auto-inscription | signale, consulte, réclame |
| `proprietaire` | Propriétaire | admin | idem utilisateur (associé à une plaque) |
| `agent_quipux` | Agent Quipux | admin | qualifie les signalements, lecture plaque, masquage |
| `agent_police` | Agent de police | admin | valide / refuse les signalements qualifiés |
| `police_terrain` | Police terrain | admin | profile pris en charge par l'application mobile |
| `service_client` | Service client | admin | répond et clôture les réclamations |
| `superviseur` | Superviseur | admin | accès total + gestion des comptes et des profils |
| `admin` | Administrateur | admin | accès total + gestion des comptes et des profils |

Workflow d'un signalement : `pending` → `constatee` (Quipux) → `validee` / `refusee` (Police).

### Inscription Utilisateur

Champs requis : **nom**, **numéro de téléphone** (identifiant de connexion),
**numéro de CNI**, **mot de passe**. La **photo de la CNI** est facultative
(endpoint `multipart/form-data`).

### Administrateur par défaut

Créé automatiquement au démarrage par `DataSeeder` (surchargeable par variables
d'environnement `APP_ADMIN_EMAIL` / `APP_ADMIN_PASSWORD`) :

- Email : `admin@circulation.ci`
- Mot de passe : `Admin123!`

## Fonctionnalités

| Route | Écran | Rôle |
|---|---|---|
| `/login` | Connexion (email ou téléphone) | public |
| `/register` | Inscription Utilisateur (nom, téléphone, CNI + photo optionnelle, mot de passe) | public |
| `/dashboard` | KPI, derniers signalements, répartition, timeline | tous |
| `/signalements` | Liste, filtres, création (JSON ou multipart photo/vidéo/plaque), détail, workflow, lecture + masquage plaque | tous |
| `/reclamations` | Réclamations (file / assignées / toutes / miennes) + messagerie + clôture | tous |
| `/notifications` | Liste, filtre non-lues, marquer lu / tout lu | tous |
| `/rapports` | Statistiques par type / statut / période (donut + histogramme) | staff |
| `/wallet` | Solde + historique des opérations | tous |
| `/profil` | Profil, mise à jour plaque, déclaration de panne | tous |
| `/utilisateurs` | Création de comptes (tous profils), rôle, activation | admin / superviseur |

## API backend

### Auth — `/api/auth`

| Méthode | Route | Corps / Description |
|---|---|---|
| POST | `/login` | `{identifier,email,phone,password}` → `{token,accessToken,user,data}` |
| POST | `/register` | JSON `{nom,prenom?,email?,phone,cni,password}` **ou** multipart (`cniPhoto`) → inscription `user` uniquement (le rôle est forcé) |
| GET | `/me` | Profil courant (JWT) → `{data:{user}}` |
| POST | `/plaque` | Met à jour la plaque → `{message,user}` |
| POST | `/activate-client` | Passe le compte en rôle **`proprietaire`** (`phone` optionnel) |
| POST | `/panne` | `{start,end}` → `enPanne=true` |
| GET | `/health` | Health check → `{status:"UP"}` |

### Types d'incivisme — `/api/infraction-types`

| Méthode | Route | Description |
|---|---|---|
| GET | `/` | `{data:[...], types:[...]}` (10 types seedés) |

### Signalements — `/api/infractions`

| Méthode | Route | Description |
|---|---|---|
| GET | `/` | Liste (filtrée selon le rôle) |
| GET | `/for-my-plate?plaque=` | Signalements liés à une plaque |
| GET | `/{id}` | Détail |
| POST | `/` | JSON ou multipart (`video`, `photo`, `plate`, `image` + champs) |
| PATCH | `/{id}/status` | Met à jour le statut `{status|statut}` (valider/refuser) |
| PATCH | `/{id}/plate` | Met à jour la plaque `{plaque}` |
| DELETE | `/{id}` | Suppression |

### Notifications — `/api/notifications`

| Méthode | Route | Description |
|---|---|---|
| GET | `/?unreadOnly=` | Liste des notifications |
| POST | `/read-all` | Marquer toutes comme lues |
| POST | `/{id}/read` | Marquer comme lue |
| GET | `/{id}` | Détail |

### Support / Réclamations — `/api/support`

| Méthode | Route | Description |
|---|---|---|
| GET | `/` | Liste |
| GET | `/queue` | File d'attente |
| GET | `/assigned` | Assignées à l'utilisateur |
| GET | `/reclamations` | Réclamations de l'utilisateur |
| POST | `/reclamations` | `{subject,message}` — créer une réclamation |
| GET | `/reclamations/{id}` | Détail réclamation |
| POST | `/reclamations/{id}/messages` | Envoyer un message |
| GET | `/reclamations/{id}/messages` | Messages d'une réclamation |
| POST | `/reclamations/{id}/close` | Clôturer la réclamation |

### Utilisateurs — `/api/users` (admin / superviseur)

| Méthode | Route | Description |
|---|---|---|
| GET | `/` | Liste tous les utilisateurs |
| POST | `/` | Création d'un compte — JSON `{nom,prenom?,email?,phone,password,role,cni?,matricule?,plaqueImmatriculation?}` **ou** multipart (`cniPhoto`) ; tous profils |
| PATCH | `/{id}/active` | Activer/désactiver `{active}` |
| PATCH | `/{id}/role` | Changer le rôle `{role}` |

### Portefeuille — `/api/wallet`

| Méthode | Route | Description |
|---|---|---|
| GET | `/` | `{data:{solde,amount,balance,operations:[...]}}` |

## Architecture

```
src/app/
  core/
    models/api.models.ts          # interfaces alignées sur le backend
    roles.ts                      # normalisation rôles + capacités
    infraction-workflow.ts        # statuts, plaque, médias
    services/                     # auth, infractions, types, notifications, support, wallet, users
    interceptors/auth.interceptor.ts  # ajoute le Bearer + logout sur 401/403
    guards/auth.guard.ts          # authGuard / guestGuard / managerGuard
  shared/icon.component.ts        # icônes SVG
  features/
    auth/                         # login, register, profile
    layout/                       # shell sidebar + topbar + router-outlet
    dashboard/ infractions/ support/ reports/ notifications/ wallet/ users/
  environments/                   # apiBaseUrl
```

Le token et l'utilisateur sont persistés dans `localStorage`
(clés `circulation_token` / `circulation_user`).
