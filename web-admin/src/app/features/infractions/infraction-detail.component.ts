import {
  Component,
  ElementRef,
  computed,
  effect,
  inject,
  input,
  linkedSignal,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { InfractionService } from '../../core/services/infraction.service';
import { AuthService } from '../../core/services/auth.service';
import { Infraction, InfractionType } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';
import { canQualify, canValidate, normalizeRole } from '../../core/roles';
import {
  infractionStatus,
  mainMedia,
  plateImage,
  plateOf,
  statusLabel,
  statusTone,
} from '../../core/infraction-workflow';

type MediaTab = 'photo' | 'video' | 'plate';
interface Rect {
  x1: number;
  y1: number;
  x2: number;
  y2: number;
}

@Component({
  selector: 'app-infraction-detail',
  imports: [DatePipe, FormsModule, IconComponent],
  template: `
    @let item = current();
    <div class="drawer-backdrop" (click)="onBackdrop($event)">
      <div class="drawer" (click)="$event.stopPropagation()">
        <header class="drawer-head">
          <div class="drawer-title">
            <div class="row" style="gap:0.5rem">
              <span class="chip blue">Dossier {{ shortId(item.id) }}</span>
              <span class="badge" [class]="statusTone(item.status || item.statut)">
                {{ statusLabel(item.status || item.statut) }}
              </span>
              @if (plateOf(item)) {
                <span class="plate-tag">{{ plateOf(item) }}</span>
              }
            </div>
            <h2>{{ typeName(item) }}</h2>
            <span class="muted small">
              Reçu le {{ item.createdAt | date: 'dd MMMM yyyy à HH:mm' }} ·
              {{ item.lieu || 'Lieu non précisé' }}
            </span>
          </div>
          <button class="icon-btn" (click)="unlockInfraction(); closed.emit()" aria-label="Fermer">
            <app-icon name="x" [size]="18" />
          </button>
        </header>

        <div class="drawer-body">
          @if (!canAccess()) {
            <div class="alert info">
              <app-icon name="lock" [size]="16" />
              <span>
                Ce dossier doit d'abord être qualifié par un agent Quipux avant de pouvoir
                être consulté par la police.
              </span>
            </div>
          }
          @if (isLockedByOther()) {
            <div class="alert info">
              <app-icon name="lock" [size]="16" />
              <span>
                Ce signalement est en cours de traitement par un autre agent.
                Vous ne pouvez pas le modifier.
              </span>
            </div>
          }
          @if (error()) {
            <div class="alert">
              <app-icon name="alert" [size]="16" />
              <span>{{ error() }}</span>
            </div>
          }
          @if (notice()) {
            <div class="alert ok">
              <app-icon name="check-circle" [size]="16" />
              <span>{{ notice() }}</span>
            </div>
          }

          <div class="steps">
            @for (step of steps(); track step.label) {
              <div
                class="step"
                [class.done]="step.state === 'done'"
                [class.current]="step.state === 'current'"
                [class.rejected]="step.state === 'rejected'"
              >
                {{ step.label }}
              </div>
            }
          </div>

          @if (normalize(role()) === 'agent_police' && infractionStatus(item) === 'pending') {
            <div class="alert info">
              <app-icon name="info" [size]="16" />
              <span>
                Ce dossier doit d'abord être qualifié par un agent Quipux avant de pouvoir
                être validé par la police.
              </span>
            </div>
          }

          <section class="stack">
            <div class="row-between">
              <h3>Preuves du signalement</h3>
              <div class="media-tabs">
                @if (mainMedia(item).type === 'image') {
                  <button
                    class="btn sm"
                    [class.secondary]="mediaTab() !== 'photo'"
                    [class.soft]="mediaTab() === 'photo'"
                    (click)="selectTab('photo')"
                  >
                    <app-icon name="image" [size]="14" /> Photo
                  </button>
                }
                @if (mainMedia(item).type === 'video') {
                  <button
                    class="btn sm"
                    [class.secondary]="mediaTab() !== 'video'"
                    [class.soft]="mediaTab() === 'video'"
                    (click)="selectTab('video')"
                  >
                    <app-icon name="video" [size]="14" /> Vidéo
                  </button>
                }
                @if (plateSrc()) {
                  <button
                    class="btn sm"
                    [class.secondary]="mediaTab() !== 'plate'"
                    [class.soft]="mediaTab() === 'plate'"
                    (click)="selectTab('plate')"
                  >
                    <app-icon name="scan-plate" [size]="14" /> Plaque
                  </button>
                }
              </div>
            </div>

            <div class="media-frame">
              @if (mediaTab() === 'photo' && mainMedia(item).type === 'image') {
                <img [src]="mainMedia(item).url" alt="Photo du signalement" />
              } @else if (mediaTab() === 'video' && mainMedia(item).type === 'video') {
                <video [src]="mainMedia(item).url" controls playsinline></video>
              } @else if (mediaTab() === 'plate' && plateSrc()) {
                <img [src]="plateSrc()" alt="Photo de la plaque" style="max-height:300px" />
              } @else {
                <div class="empty">
                  <div class="empty-icon"><app-icon name="image" [size]="22" /></div>
                  <strong>Aucun média</strong>
                  <p>Ce signalement ne contient pas de photo ou de vidéo exploitable.</p>
                </div>
              }
            </div>
          </section>

          <section class="plate-panel">
            <div class="row-between">
              <div>
                <h3 style="display:flex;align-items:center;gap:0.4rem">
                  <app-icon name="scan-plate" [size]="17" />
                  Lecture de la plaque
                </h3>
                <span class="help">
                  Saisissez la plaque lue sur la preuve, puis masquez-la si nécessaire.
                </span>
              </div>
              @if (plateOf(current())) {
                <span class="plate-tag">{{ plateOf(current()) }}</span>
              } @else {
                <span class="badge pending">Non lue</span>
              }
            </div>

            <div class="plate-editor">
              <input
                type="text"
                [ngModel]="plateValue()"
                (ngModelChange)="plateValue.set($event.toUpperCase())"
                placeholder="AB-1234-CD"
                maxlength="14"
                aria-label="Plaque d'immatriculation"
                [disabled]="isLockedByOther()"
              />
              <button
                class="btn sm"
                (click)="savePlate()"
                [disabled]="plateBusy() || !plateValue().trim() || isLockedByOther()"
              >
                <app-icon name="check" [size]="14" />
                {{ plateBusy() ? 'Enregistrement…' : 'Enregistrer' }}
              </button>
            </div>

            @if (plateSrc()) {
              <div class="canvas-wrap">
                <canvas
                  #plateCanvas
                  (pointerdown)="startDraw($event)"
                  (pointermove)="moveDraw($event)"
                  (pointerup)="endDraw()"
                  (pointerleave)="endDraw()"
                ></canvas>
              </div>
              <div class="canvas-hint">
                <app-icon name="eye-off" [size]="14" />
                Glissez un rectangle sur la plaque pour l'anonymiser avant export.
              </div>
              <div class="row">
                <button class="btn sm secondary" (click)="applyMask()" [disabled]="!selection()">
                  <app-icon name="eye-off" [size]="14" />
                  Masquer la sélection
                </button>
                <button class="btn sm ghost" (click)="resetMask()">
                  <app-icon name="refresh" [size]="14" />
                  Réinitialiser
                </button>
                <button class="btn sm ghost" (click)="downloadMasked()">
                  <app-icon name="download" [size]="14" />
                  Télécharger
                </button>
              </div>
            } @else {
              <div class="alert info">
                <app-icon name="info" [size]="16" />
                <span>
                  Aucune photo de plaque disponible. Utilisez la photo principale ou
                  saisissez la plaque manuellement.
                </span>
              </div>
            }
          </section>

          <section class="stack">
            <h3>Informations du dossier</h3>
            <div class="detail-grid">
              <div class="detail-item">
                <span class="detail-label">Type d'infraction</span>
                <span class="detail-value">{{ typeName(item) }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Plaque</span>
                <span class="detail-value">{{ plateOf(item) || 'Non renseignée' }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Lieu</span>
                <span class="detail-value">{{ item.lieu || '—' }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Coordonnées GPS</span>
                <span class="detail-value">
                  @if (item.latitude != null && item.longitude != null) {
                    {{ item.latitude }}, {{ item.longitude }}
                  } @else {
                    —
                  }
                </span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Signalé par</span>
                <span class="detail-value">{{ item.clientName || item.userName || '—' }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Agent en charge</span>
                <span class="detail-value">{{ item.agentName || 'Non assigné' }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Priorité</span>
                <span class="detail-value">{{ item.priority || 'Normale' }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Dernière mise à jour</span>
                <span class="detail-value">
                  {{ item.updatedAt ? (item.updatedAt | date: 'dd/MM/yyyy HH:mm') : '—' }}
                </span>
              </div>
            </div>

            @if (item.description) {
              <div class="detail-item">
                <span class="detail-label">Description</span>
                <span class="detail-value">{{ item.description }}</span>
              </div>
            }
          </section>

          <section class="stack">
            <h3>Historique du traitement</h3>
            <div class="timeline">
              @for (event of timeline(); track event.title) {
                <div class="tl-item">
                  <div class="tl-dot" [class]="event.tone">
                    <app-icon [name]="event.icon" [size]="13" />
                  </div>
                  <div class="tl-content">
                    <strong>{{ event.title }}</strong>
                    <p>{{ event.detail }}</p>
                  </div>
                </div>
              }
            </div>
          </section>
        </div>

        <footer class="drawer-foot">
          <button class="btn ghost" (click)="unlockInfraction(); closed.emit()">Fermer</button>
          <div class="spacer"></div>

          @if (qualify() && infractionStatus(item) === 'pending') {
            <button
              class="btn danger-soft"
              (click)="updateStatus('refusee')"
              [disabled]="busy() || !canAccess()"
            >
              <app-icon name="x" [size]="15" />
              Signaler non conforme
            </button>
            <button class="btn success" (click)="updateStatus('constatee')" [disabled]="busy() || !canAccess()">
              @if (busy()) {
                <span class="spinner" style="width:15px;height:15px;border-width:2px;border-top-color:#fff"></span>
              } @else {
                <app-icon name="check" [size]="15" />
              }
              Confirmer l'infraction
            </button>
          } @else if (validate() && infractionStatus(item) === 'constatee') {
            <button class="btn danger-soft" (click)="updateStatus('refusee')" [disabled]="busy() || !canAccess()">
              <app-icon name="x" [size]="15" />
              Refuser
            </button>
            <button class="btn success" (click)="updateStatus('validee')" [disabled]="busy() || !canAccess()">
              @if (busy()) {
                <span class="spinner" style="width:15px;height:15px;border-width:2px;border-top-color:#fff"></span>
              } @else {
                <app-icon name="check" [size]="15" />
              }
              Valider le signalement
            </button>
          } @else if (isManager() && infractionStatus(item) !== 'pending') {
            <button class="btn secondary" (click)="updateStatus('pending')" [disabled]="busy() || !canAccess()">
              <app-icon name="refresh" [size]="15" />
              Réouvrir la qualification
            </button>
          } @else {
            <span class="muted small">
              @switch (infractionStatus(item)) {
                @case ('pending') {
                  En attente de qualification par un agent Quipux.
                }
                @case ('constatee') {
                  En attente de décision d'un agent de police.
                }
                @case ('validee') {
                  Dossier validé — aucune action requise.
                }
                @case ('refusee') {
                  Dossier refusé — clôturé.
                }
              }
            </span>
          }
        </footer>
      </div>
    </div>
  `,
})
export class InfractionDetailComponent {
  private readonly service = inject(InfractionService);
  private readonly auth = inject(AuthService);

  readonly infraction = input.required<Infraction>();
  readonly types = input<InfractionType[]>([]);
  readonly updated = output<Infraction>();
  readonly closed = output<void>();

  readonly role = this.auth.role;
  readonly qualify = computed(() => canQualify(this.auth.role()));
  readonly validate = computed(() => canValidate(this.auth.role()));
  readonly isManager = computed(() => {
    const role = normalizeRole(this.auth.role());
    return role === 'admin' || role === 'superviseur';
  });

  readonly override = linkedSignal(() => {
    this.infraction();
    return null as Infraction | null;
  });
  readonly current = computed(() => this.override() ?? this.infraction());
  readonly mediaTab = linkedSignal(() => this.initialTab());

  readonly isLockedByOther = computed(() => {
    const item = this.current();
    const currentUserId = this.auth.user()?.userId;
    if (!item.lockedByUserId || !currentUserId) return false;
    return item.lockedByUserId !== currentUserId;
  });

  readonly canAccess = computed(() => {
    // Agent police ne peut pas accéder aux dossiers en attente de qualification
    if (this.validate() && !this.qualify() && infractionStatus(this.current()) === 'pending') {
      return false;
    }
    return !this.isLockedByOther();
  });

  readonly plateValue = linkedSignal(() => plateOf(this.infraction()));
  readonly plateBusy = signal(false);
  readonly busy = signal(false);
  readonly error = signal<string | null>(null);
  readonly notice = signal<string | null>(null);
  readonly lockBusy = signal(false);

  readonly canvasRef = viewChild<ElementRef<HTMLCanvasElement>>('plateCanvas');
  readonly selection = signal<Rect | null>(null);
  private baseImage: HTMLImageElement | null = null;
  private drawing = false;
  private startPoint = { x: 0, y: 0 };

  constructor() {
    effect(() => {
      const canvas = this.canvasRef();
      const src = this.plateSrc();
      if (canvas && src) {
        this.drawPlateImage();
      }
    });

    effect(() => {
      const item = this.infraction();
      if (item && !item.lockedByUserId && (this.qualify() || this.validate()) && this.canAccess()) {
        this.lockInfraction();
      }
    });
  }

  readonly plateSrc = computed(() => {
    const item = this.current();
    return plateImage(item) ?? (mainMedia(item).type === 'image' ? mainMedia(item).url : null);
  });

  readonly steps = computed(() => {
    const status = infractionStatus(this.current());
    return [
      { label: 'Réception', state: 'done' as const },
      {
        label: 'Qualification Quipux',
        state:
          status === 'pending'
            ? ('current' as const)
            : status === 'refusee'
              ? ('rejected' as const)
              : ('done' as const),
      },
      {
        label: 'Décision police',
        state:
          status === 'constatee'
            ? ('current' as const)
            : status === 'validee'
              ? ('done' as const)
              : status === 'refusee'
                ? ('rejected' as const)
                : ('current' as const),
      },
      {
        label: 'Clôture',
        state: status === 'validee' ? ('done' as const) : ('current' as const),
      },
    ];
  });

  readonly timeline = computed(() => {
    const item = this.current();
    const status = infractionStatus(item);
    const received = item.createdAt
      ? new Date(item.createdAt).toLocaleString('fr-FR')
      : 'Date inconnue';
    const updated = item.updatedAt
      ? new Date(item.updatedAt).toLocaleString('fr-FR')
      : received;

    const events = [
      {
        title: 'Signalement reçu',
        detail: `${item.clientName || item.userName || 'Usager'} · ${received}`,
        icon: 'reports',
        tone: 'done',
      },
      {
        title: 'Qualification Quipux',
        detail:
          status === 'pending'
            ? 'En attente de traitement par un agent Quipux.'
            : status === 'refusee'
              ? `Non conforme · ${updated}`
              : `Infraction confirmée · ${updated}`,
        icon: status === 'pending' ? 'clock' : status === 'refusee' ? 'x' : 'scan-plate',
        tone:
          status === 'pending' ? 'current' : status === 'refusee' ? 'rejected' : 'done',
      },
      {
        title: 'Décision police',
        detail:
          status === 'validee'
            ? `Signalement validé · ${updated}`
            : status === 'refusee'
              ? `Signalement refusé · ${updated}`
              : 'En attente de décision.',
        icon: status === 'validee' ? 'check' : status === 'refusee' ? 'x' : 'shield',
        tone:
          status === 'validee'
            ? 'done'
            : status === 'refusee'
              ? 'rejected'
              : 'current',
      },
    ];
    return events;
  });

  plateOf = plateOf;
  statusLabel = statusLabel;
  statusTone = statusTone;
  mainMedia = mainMedia;
  infractionStatus = infractionStatus;
  normalize = normalizeRole;

  shortId(id: string): string {
    return id ? id.slice(0, 8).toUpperCase() : '—';
  }

  typeName(i: Infraction): string {
    const id = i.typeId ?? i.inciviTypeId;
    return this.types().find((t) => t.id === id)?.nom ?? id ?? 'Infraction';
  }

  selectTab(tab: MediaTab): void {
    this.mediaTab.set(tab);
    if (tab === 'plate') {
      setTimeout(() => this.drawPlateImage(), 0);
    }
  }

  updateStatus(status: string): void {
    this.busy.set(true);
    this.error.set(null);
    this.notice.set(null);
    const item = this.current();
    this.service.updateStatus(item.id, status).subscribe({
      next: (res) => {
        this.busy.set(false);
        const updated = { ...item, ...(res.data ?? {}), status, statut: status };
        this.override.set(updated);
        this.notice.set(
          status === 'constatee'
            ? 'Infraction confirmée. Le dossier est transmis à la police.'
            : status === 'validee'
              ? 'Signalement validé avec succès.'
              : status === 'refusee'
                ? 'Le signalement a été refusé.'
                : 'Le dossier a été réouvert.',
        );
        this.updated.emit(updated);
      },
      error: (err) => {
        this.busy.set(false);
        this.error.set(err?.error?.message ?? 'Impossible de mettre à jour le statut.');
      },
    });
  }

  savePlate(): void {
    const value = this.plateValue().trim();
    if (!value) return;
    const item = this.current();
    this.plateBusy.set(true);
    this.error.set(null);
    this.service.updatePlate(item.id, value).subscribe({
      next: (res) => {
        this.plateBusy.set(false);
        const updated = {
          ...item,
          ...(res.data ?? {}),
          plaqueImmatriculation: value,
          numeroImmatriculation: value,
        };
        this.override.set(updated);
        this.notice.set('Lecture de la plaque enregistrée.');
        this.updated.emit(updated);
      },
      error: (err) => {
        this.plateBusy.set(false);
        this.error.set(err?.error?.message ?? "Impossible d'enregistrer la plaque.");
      },
    });
  }

  onBackdrop(event: Event): void {
    if (event.target === event.currentTarget) {
      this.unlockInfraction();
      this.closed.emit();
    }
  }

  /* ---------- Plate masking tool ---------- */

  private initialTab(): MediaTab {
    const media = mainMedia(this.infraction());
    if (media.type === 'image') return 'photo';
    if (media.type === 'video') return 'video';
    return 'plate';
  }

  private drawPlateImage(): void {
    const canvas = this.canvasRef()?.nativeElement;
    const src = this.plateSrc();
    if (!canvas || !src) return;
    const img = new Image();
    img.onload = () => {
      canvas.width = img.naturalWidth;
      canvas.height = img.naturalHeight;
      this.baseImage = img;
      this.selection.set(null);
      this.redraw();
    };
    img.src = src;
  }

  private redraw(): void {
    const canvas = this.canvasRef()?.nativeElement;
    if (!canvas || !this.baseImage) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(this.baseImage, 0, 0);
    const sel = this.selection();
    if (sel) {
      const x = Math.min(sel.x1, sel.x2);
      const y = Math.min(sel.y1, sel.y2);
      const w = Math.abs(sel.x2 - sel.x1);
      const h = Math.abs(sel.y2 - sel.y1);
      ctx.fillStyle = 'rgba(37, 99, 235, 0.22)';
      ctx.fillRect(x, y, w, h);
      ctx.strokeStyle = '#2563eb';
      ctx.lineWidth = Math.max(2, canvas.width / 400);
      ctx.setLineDash([6, 4]);
      ctx.strokeRect(x, y, w, h);
      ctx.setLineDash([]);
    }
  }

  private point(event: PointerEvent, canvas: HTMLCanvasElement): { x: number; y: number } {
    const rect = canvas.getBoundingClientRect();
    return {
      x: ((event.clientX - rect.left) / rect.width) * canvas.width,
      y: ((event.clientY - rect.top) / rect.height) * canvas.height,
    };
  }

  startDraw(event: PointerEvent): void {
    const canvas = this.canvasRef()?.nativeElement;
    if (!canvas || !this.baseImage) return;
    const p = this.point(event, canvas);
    this.drawing = true;
    this.startPoint = p;
    this.selection.set({ x1: p.x, y1: p.y, x2: p.x, y2: p.y });
    canvas.setPointerCapture(event.pointerId);
  }

  moveDraw(event: PointerEvent): void {
    if (!this.drawing) return;
    const canvas = this.canvasRef()?.nativeElement;
    if (!canvas) return;
    const p = this.point(event, canvas);
    this.selection.set({
      x1: this.startPoint.x,
      y1: this.startPoint.y,
      x2: p.x,
      y2: p.y,
    });
    this.redraw();
  }

  endDraw(): void {
    if (!this.drawing) return;
    this.drawing = false;
    const sel = this.selection();
    if (sel && (Math.abs(sel.x2 - sel.x1) < 6 || Math.abs(sel.y2 - sel.y1) < 6)) {
      this.selection.set(null);
      this.redraw();
    }
  }

  applyMask(): void {
    const canvas = this.canvasRef()?.nativeElement;
    const sel = this.selection();
    if (!canvas || !sel) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const x = Math.max(0, Math.min(sel.x1, sel.x2));
    const y = Math.max(0, Math.min(sel.y1, sel.y2));
    const w = Math.min(canvas.width - x, Math.abs(sel.x2 - sel.x1));
    const h = Math.min(canvas.height - y, Math.abs(sel.y2 - sel.y1));
    if (w < 2 || h < 2) return;

    const pixelSize = Math.max(6, Math.round(Math.min(w, h) / 8));
    const small = document.createElement('canvas');
    small.width = Math.max(1, Math.round(w / pixelSize));
    small.height = Math.max(1, Math.round(h / pixelSize));
    const smallCtx = small.getContext('2d');
    if (!smallCtx) return;
    smallCtx.drawImage(canvas, x, y, w, h, 0, 0, small.width, small.height);

    ctx.save();
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(small, 0, 0, small.width, small.height, x, y, w, h);
    ctx.strokeStyle = 'rgba(15, 23, 42, 0.35)';
    ctx.lineWidth = Math.max(1, canvas.width / 800);
    ctx.strokeRect(x, y, w, h);
    ctx.restore();

    this.selection.set(null);
    this.notice.set('Plaque masquée sur l’aperçu. Téléchargez l’image anonymisée.');
  }

  resetMask(): void {
    this.selection.set(null);
    this.redraw();
    this.notice.set(null);
  }

  downloadMasked(): void {
    const canvas = this.canvasRef()?.nativeElement;
    if (!canvas) return;
    const link = document.createElement('a');
    link.download = `signalement-${this.current().id.slice(0, 8)}-plaque-masquee.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
  }

  private lockInfraction(): void {
    const item = this.current();
    if (!item || item.lockedByUserId) return;
    this.lockBusy.set(true);
    this.service.lock(item.id).subscribe({
      next: (res) => {
        this.lockBusy.set(false);
        const updated = { ...item, ...(res.data ?? {}) };
        this.override.set(updated);
      },
      error: () => {
        this.lockBusy.set(false);
      },
    });
  }

  unlockInfraction(): void {
    const item = this.current();
    if (!item || !item.lockedByUserId) return;
    this.service.unlock(item.id).subscribe({
      next: (res) => {
        const updated = { ...item, ...(res.data ?? {}), lockedBy: undefined, lockedByUserId: undefined, lockedAt: undefined };
        this.override.set(updated);
      },
      error: () => {},
    });
  }
}
