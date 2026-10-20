import { User } from './models/api.models';

export type StaffRole =
  | 'agent_quipux'
  | 'agent_police'
  | 'police_terrain'
  | 'service_client'
  | 'superviseur'
  | 'admin';

export type CitizenRole = 'user' | 'proprietaire';

export type AppRole = StaffRole | CitizenRole | 'guest';

export const ROLE_OPTIONS: AppRole[] = [
  'user',
  'proprietaire',
  'agent_quipux',
  'agent_police',
  'police_terrain',
  'service_client',
  'superviseur',
  'admin',
];

const ROLE_ALIASES: Record<string, AppRole> = {
  user: 'user',
  utilisateur: 'user',
  usager: 'user',
  proprietaire: 'proprietaire',
  'propriétaire': 'proprietaire',
  owner: 'proprietaire',
  client: 'proprietaire',
  agent_quipux: 'agent_quipux',
  agentquipux: 'agent_quipux',
  agent_police: 'agent_police',
  agentpolice: 'agent_police',
  police_terrain: 'police_terrain',
  policeterrain: 'police_terrain',
  service_client: 'service_client',
  serviceclient: 'service_client',
  superviseur: 'superviseur',
  supervisor: 'superviseur',
  admin: 'admin',
  administrateur: 'admin',
};

export const ROLE_LABELS: Record<string, string> = {
  user: 'Utilisateur',
  proprietaire: 'Propriétaire',
  agent_quipux: 'Agent Quipux',
  agent_police: 'Agent de police',
  police_terrain: 'Police terrain',
  service_client: 'Service client',
  superviseur: 'Superviseur',
  admin: 'Administrateur',
  guest: 'Invité',
};

export function normalizeRole(raw?: string | null): AppRole {
  if (!raw) return 'guest';
  return ROLE_ALIASES[raw.trim().toLowerCase()] ?? (raw as AppRole);
}

export function roleLabel(raw?: string | null): string {
  const role = normalizeRole(raw);
  return ROLE_LABELS[role] ?? raw ?? '—';
}

const STAFF: AppRole[] = [
  'agent_quipux',
  'agent_police',
  'police_terrain',
  'service_client',
  'superviseur',
  'admin',
];

export function isStaff(raw?: string | null): boolean {
  return STAFF.includes(normalizeRole(raw));
}

export function isCitizen(raw?: string | null): boolean {
  const role = normalizeRole(raw);
  return role === 'user' || role === 'proprietaire';
}

export function canManageUsers(raw?: string | null): boolean {
  const role = normalizeRole(raw);
  return role === 'admin' || role === 'superviseur';
}

export function canQualify(raw?: string | null): boolean {
  const role = normalizeRole(raw);
  return role === 'admin' || role === 'superviseur' || role === 'agent_quipux';
}

export function canValidate(raw?: string | null): boolean {
  const role = normalizeRole(raw);
  return role === 'admin' || role === 'superviseur' || role === 'agent_police';
}

export function canSupport(raw?: string | null): boolean {
  const role = normalizeRole(raw);
  return role === 'admin' || role === 'superviseur' || role === 'service_client';
}

export function displayName(user?: User | null): string {
  if (!user) return 'Utilisateur';
  if (user.fullName) return user.fullName;
  const composed = [user.prenom, user.nom].filter(Boolean).join(' ').trim();
  return composed || user.email || user.phone || 'Utilisateur';
}

export function initials(user?: User | null): string {
  const name = displayName(user);
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0))
    .join('')
    .toUpperCase();
}
