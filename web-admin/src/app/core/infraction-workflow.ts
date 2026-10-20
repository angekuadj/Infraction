import { Infraction } from './models/api.models';

export type WorkflowStatus = 'pending' | 'constatee' | 'validee' | 'refusee';

const STATUS_ALIASES: Record<string, WorkflowStatus> = {
  pending: 'pending',
  en_attente: 'pending',
  attente: 'pending',
  nouvelle: 'pending',
  nouveau: 'pending',
  ouvert: 'pending',
  ouverte: 'pending',
  new: 'pending',
  constatee: 'constatee',
  constatée: 'constatee',
  qualifiee: 'constatee',
  qualifiée: 'constatee',
  validee_quipux: 'constatee',
  processed: 'constatee',
  en_cours: 'constatee',
  in_progress: 'constatee',
  validee: 'validee',
  validée: 'validee',
  validee_police: 'validee',
  approved: 'validee',
  approuvee: 'validee',
  confirmee: 'validee',
  confirmed: 'validee',
  refusee: 'refusee',
  refusée: 'refusee',
  rejetee: 'refusee',
  rejected: 'refusee',
  close: 'refusee',
  closed: 'refusee',
  fermee: 'refusee',
};

export function normalizeWorkflowStatus(raw?: string | null): WorkflowStatus {
  if (!raw) return 'pending';
  return STATUS_ALIASES[raw.trim().toLowerCase()] ?? 'pending';
}

export function infractionStatus(i: Infraction): WorkflowStatus {
  return normalizeWorkflowStatus(i.status ?? i.statut);
}

export function statusLabel(raw?: string | null): string {
  switch (normalizeWorkflowStatus(raw)) {
    case 'pending':
      return 'À qualifier';
    case 'constatee':
      return 'En attente police';
    case 'validee':
      return 'Validée';
    case 'refusee':
      return 'Refusée';
  }
}

export function statusTone(raw?: string | null): string {
  switch (normalizeWorkflowStatus(raw)) {
    case 'pending':
      return 'pending';
    case 'constatee':
      return 'constatee';
    case 'validee':
      return 'validee';
    case 'refusee':
      return 'refusee';
  }
}

export function workflowStep(raw?: string | null): number {
  switch (normalizeWorkflowStatus(raw)) {
    case 'pending':
      return 0;
    case 'constatee':
      return 1;
    case 'validee':
      return 3;
    case 'refusee':
      return 2;
  }
}

export function plateOf(i: Infraction): string {
  return (i.plaqueImmatriculation ?? i.numeroImmatriculation ?? '').trim();
}

export function locationOf(i: Infraction): string {
  return i.lieu ?? '—';
}

export function mediaUrl(url?: string | null): string | null {
  if (!url) return null;
  if (url.startsWith('/')) return url;
  try {
    const parsed = new URL(url, window.location.origin);
    if (parsed.pathname.startsWith('/uploads/')) return parsed.pathname;
    return url;
  } catch {
    return url;
  }
}

export function mainMedia(i: Infraction): { type: 'video' | 'image' | null; url: string | null } {
  const video = mediaUrl(i.videoUrl);
  const image = mediaUrl(i.imageUrl);
  if (image) return { type: 'image', url: image };
  if (video) return { type: 'video', url: video };
  return { type: null, url: null };
}

export function plateImage(i: Infraction): string | null {
  return mediaUrl(i.plateImagePath ?? null);
}

export function isSlaLate(i: Infraction): boolean {
  if (!i.createdAt) return false;
  const created = new Date(i.createdAt).getTime();
  if (Number.isNaN(created)) return false;
  return Date.now() - created > 48 * 60 * 60 * 1000 && infractionStatus(i) === 'pending';
}
