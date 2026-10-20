export type ApiRole =
  | 'user'
  | 'proprietaire'
  | 'agent_quipux'
  | 'agent_police'
  | 'police_terrain'
  | 'service_client'
  | 'superviseur'
  | 'admin';

export interface User {
  id: string;
  userId?: string;
  nom?: string;
  prenom?: string;
  fullName?: string;
  email?: string;
  phone?: string;
  telephone?: string;
  role: ApiRole | string;
  plaqueImmatriculation?: string;
  numeroImmatriculation?: string;
  matricule?: string;
  agentPolice?: string;
  cni?: string;
  cniPhotoPath?: string;
  cniPhotoUrl?: string;
  isActive?: boolean;
  active?: boolean;
  enPanne?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface AuthResponse {
  token: string;
  accessToken?: string;
  tokenType?: string;
  user: User;
  data?: { token?: string; user?: User };
}

export interface LoginRequest {
  identifier: string;
  password: string;
}

export interface RegisterRequest {
  nom: string;
  prenom?: string;
  email?: string;
  phone: string;
  password: string;
  cni: string;
}

export interface CreateUserRequest {
  nom: string;
  prenom?: string;
  email?: string;
  phone: string;
  password: string;
  role: ApiRole;
  cni?: string;
  matricule?: string;
  plaqueImmatriculation?: string;
}

export interface InfractionType {
  id: string;
  nom: string;
  name?: string;
  description?: string;
  category?: string;
  categorie?: string;
  ordre?: number;
  actif?: boolean;
}

export interface Infraction {
  id: string;
  serverId?: string;
  localId?: string;
  typeId?: string;
  inciviTypeId?: string;
  plaqueImmatriculation?: string;
  numeroImmatriculation?: string;
  plaque?: string;
  description?: string;
  commentaire?: string;
  lieu?: string;
  adresse?: string;
  latitude?: number;
  longitude?: number;
  status?: string;
  statut?: string;
  priority?: string;
  videoUrl?: string;
  imageUrl?: string;
  videoPath?: string;
  photoPath?: string;
  plateImagePath?: string;
  thumbnailPath?: string;
  clientId?: string;
  clientName?: string;
  userId?: string;
  userName?: string;
  agentName?: string;
  agentPolice?: string;
  createdAt?: string;
  updatedAt?: string;
  reportedAt?: string;
  sentAt?: string;
  score?: number;
  isAnalyzed?: boolean;
  enPanne?: boolean;
  lockedBy?: string;
  lockedAt?: string;
  lockedByUserId?: string;
}

export interface AppNotification {
  id: string;
  title?: string;
  body?: string;
  type?: string;
  read: boolean;
  seen?: boolean;
  createdAt?: string;
}

export interface Reclamation {
  id: string;
  subject: string;
  message: string;
  status?: string;
  statut?: string;
  clientId?: string;
  clientName?: string;
  userId?: string;
  userName?: string;
  assignedTo?: string;
  agentName?: string;
  closed: boolean;
  closedAt?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface SupportMessage {
  id: string;
  reclamationId: string;
  sender?: string;
  senderName?: string;
  body: string;
  fromClient: boolean;
  fromAgent: boolean;
  createdAt?: string;
}

export interface WalletOperation {
  id: string;
  type?: string;
  amount: number;
  description?: string;
  label?: string;
  date?: string;
}

export interface Wallet {
  id: string;
  userId: string;
  solde: number;
  amount?: number;
  balance?: number;
  operations: WalletOperation[];
  updatedAt?: string;
}

export interface ApiErrorBody {
  message?: string;
  error?: string;
  code?: string;
  statusCode?: number;
}
