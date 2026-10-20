import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { InfractionService } from '../../core/services/infraction.service';
import { InfractionTypeService } from '../../core/services/infraction-type.service';
import { AuthService } from '../../core/services/auth.service';
import { Infraction, InfractionType } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';
import { InfractionDetailComponent } from './infraction-detail.component';
import { canQualify, canValidate, isStaff, normalizeRole } from '../../core/roles';
import {
  infractionStatus,
  mainMedia,
  plateOf,
  statusLabel,
  statusTone,
  WorkflowStatus,
} from '../../core/infraction-workflow';

type Tab = 'all' | WorkflowStatus;

@Component({
  selector: 'app-infractions',
  imports: [FormsModule, DatePipe, IconComponent, InfractionDetailComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Traitement</span>
        <h1>{{ pageTitle() }}</h1>
        <span class="page-sub">{{ pageSubtitle() }}</span>
      </div>
      <div class="btn-group">
        <button class="btn secondary" (click)="load()" [disabled]="loading()">
          <app-icon name="refresh" [size]="16" />
          Actualiser
        </button>
        <button class="btn" (click)="openForm()">
          <app-icon name="plus" [size]="16" />
          Nouveau signalement
        </button>
      </div>
    </div>

    <div class="card flush section">
      <div style="padding: 0 1.25rem">
        <div class="tabs">
          <button class="tab" [class.active]="tab() === 'all'" (click)="setTab('all')">
            Tous
            <span class="tab-count">{{ total() }}</span>
          </button>
          <button class="tab" [class.active]="tab() === 'pending'" (click)="setTab('pending')">
            À qualifier
            <span class="tab-count">{{ counts().pending }}</span>
          </button>
          <button class="tab" [class.active]="tab() === 'constatee'" (click)="setTab('constatee')">
            En attente police
            <span class="tab-count">{{ counts().constatee }}</span>
          </button>
          <button class="tab" [class.active]="tab() === 'validee'" (click)="setTab('validee')">
            Validés
            <span class="tab-count">{{ counts().validee }}</span>
          </button>
          <button class="tab" [class.active]="tab() === 'refusee'" (click)="setTab('refusee')">
            Refusés
            <span class="tab-count">{{ counts().refusee }}</span>
          </button>
        </div>
      </div>

      <div class="toolbar" style="padding: 0.9rem 1.25rem">
        <div class="search-input">
          <app-icon name="search" [size]="16" />
          <input
            type="search"
            [ngModel]="search()"
            (ngModelChange)="search.set($event)"
            placeholder="Rechercher une plaque, un lieu, un usager…"
          />
        </div>
        <select
          class="input"
          style="max-width: 240px"
          [ngModel]="typeFilter()"
          (ngModelChange)="typeFilter.set($event)"
          aria-label="Filtrer par type"
        >
          <option value="">Tous les types</option>
          @for (t of types(); track t.id) {
            <option [value]="t.id">{{ t.nom }}</option>
          }
        </select>
        <div class="spacer"></div>
        <span class="muted small">{{ filtered().length }} dossier(s)</span>
      </div>

      @if (loading()) {
        <div class="loading">
          <span class="spinner"></span>
          Chargement des signalements…
        </div>
      } @else {
        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>Signalement</th>
                <th>Plaque</th>
                <th>Lieu</th>
                <th>Statut</th>
                <th>Signalé par</th>
                <th>Date</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              @for (i of filtered(); track i.id) {
                <tr class="clickable" (click)="open(i)" [class.locked]="isLockedByOther(i)">
                  <td>
                    <div class="cell-media">
                      @if (thumb(i); as src) {
                        <img class="thumb" [src]="src" alt="" />
                      } @else {
                        <div class="thumb-placeholder"><app-icon name="image" [size]="18" /></div>
                      }
                      <div>
                        <div class="cell-main">{{ typeName(i) }}</div>
                        <div class="cell-sub">{{ i.description || 'Sans description' }}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    @if (plateOf(i)) {
                      <span class="plate-tag">{{ plateOf(i) }}</span>
                    } @else {
                      <button
                        class="btn ghost sm"
                        style="padding:0.15rem 0.35rem"
                        (click)="$event.stopPropagation(); open(i)"
                      >
                        Lire la plaque
                      </button>
                    }
                  </td>
                  <td>
                    <div>{{ i.lieu || '—' }}</div>
                    @if (i.latitude != null && i.longitude != null) {
                      <div class="cell-sub mono">{{ i.latitude }}, {{ i.longitude }}</div>
                    }
                  </td>
                  <td>
                    <span class="badge" [class]="statusTone(i.status || i.statut)">
                      {{ statusLabel(i.status || i.statut) }}
                    </span>
                  </td>
                  <td>
                    <div>{{ i.clientName || i.userName || '—' }}</div>
                    <div class="cell-sub">{{ i.agentName || 'Non assigné' }}</div>
                  </td>
                  <td class="muted small nowrap">
                    {{ i.createdAt | date: 'dd/MM/yyyy' }}
                    <div class="cell-sub">{{ i.createdAt | date: 'HH:mm' }}</div>
                  </td>
                  <td>
                    <div class="actions">
                      @if (canDelete()) {
                        <button
                          class="btn ghost icon sm"
                          title="Supprimer"
                          (click)="$event.stopPropagation(); remove(i)"
                        >
                          <app-icon name="trash" [size]="15" />
                        </button>
                      }
                      <app-icon name="chevron-right" [size]="16" />
                    </div>
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="7">
                    <div class="empty">
                      <div class="empty-icon"><app-icon name="reports" [size]="22" /></div>
                      <strong>Aucun signalement dans cette vue</strong>
                      <p>
                        Aucun dossier ne correspond à vos filtres. Modifiez la recherche ou
                        créez un nouveau signalement.
                      </p>
                      <button class="btn sm secondary" (click)="resetFilters()">
                        Réinitialiser les filtres
                      </button>
                    </div>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      }
    </div>

    @if (selected(); as item) {
      <app-infraction-detail
        [infraction]="item"
        [types]="types()"
        (updated)="onUpdated($event)"
        (closed)="closeDetail()"
      />
    }

    @if (showForm()) {
      <div class="modal-backdrop" (click)="onBackdrop($event)">
        <div class="modal wide" (click)="$event.stopPropagation()">
          <div class="modal-head">
            <div class="drawer-title">
              <span class="eyebrow">Nouveau dossier</span>
              <h2>Créer un signalement</h2>
              <span class="muted small">
                Ajoutez une photo ou une vidéo, puis renseignez la plaque du véhicule.
              </span>
            </div>
            <button class="icon-btn" (click)="showForm.set(false)" aria-label="Fermer">
              <app-icon name="x" [size]="18" />
            </button>
          </div>

          <div class="modal-body">
            @if (formError()) {
              <div class="alert">
                <app-icon name="alert" [size]="16" />
                <span>{{ formError() }}</span>
              </div>
            }

            <div class="form-grid">
              <label>
                Type d'infraction
                <select [(ngModel)]="form.typeId">
                  <option value="">— Choisir —</option>
                  @for (t of types(); track t.id) {
                    <option [value]="t.id">{{ t.nom }}</option>
                  }
                </select>
              </label>
              <label>
                Plaque d'immatriculation
                <input
                  type="text"
                  [(ngModel)]="form.plaqueImmatriculation"
                  placeholder="AB-1234-CD"
                  style="text-transform:uppercase"
                />
              </label>
              <label>
                Lieu
                <input type="text" [(ngModel)]="form.lieu" placeholder="Commune, rue, repère…" />
              </label>
              <label>
                Priorité
                <select [(ngModel)]="form.priority">
                  <option value="normale">Normale</option>
                  <option value="haute">Haute</option>
                  <option value="urgente">Urgente</option>
                </select>
              </label>
              <label>
                Latitude
                <input type="number" [(ngModel)]="form.latitude" placeholder="5.3599" />
              </label>
              <label>
                Longitude
                <input type="number" [(ngModel)]="form.longitude" placeholder="-4.0083" />
              </label>
            </div>

            <label>
              Description
              <textarea
                [(ngModel)]="form.description"
                rows="3"
                placeholder="Décrivez la situation, le véhicule et les circonstances…"
              ></textarea>
            </label>

            <div class="form-grid">
              <label
                class="dropzone"
                [class.filled]="!!photoName()"
                (dragover)="onDragOver($event)"
                (drop)="onDrop($event, 'photo')"
              >
                <app-icon [name]="photoName() ? 'check-circle' : 'image'" [size]="22" />
                <strong>{{ photoName() || 'Photo du signalement' }}</strong>
                <span>{{ photoName() ? 'Fichier prêt à être envoyé' : 'Cliquez ou déposez une image' }}</span>
                <input type="file" accept="image/*" (change)="onPhoto($event)" />
              </label>

              <label
                class="dropzone"
                [class.filled]="!!videoName()"
                (dragover)="onDragOver($event)"
                (drop)="onDrop($event, 'video')"
              >
                <app-icon [name]="videoName() ? 'check-circle' : 'video'" [size]="22" />
                <strong>{{ videoName() || 'Vidéo' }}</strong>
                <span>{{ videoName() ? 'Fichier prêt à être envoyé' : 'Cliquez ou déposez une vidéo' }}</span>
                <input type="file" accept="video/*" (change)="onVideo($event)" />
              </label>

              <label
                class="dropzone"
                [class.filled]="!!plateName()"
                (dragover)="onDragOver($event)"
                (drop)="onDrop($event, 'plate')"
              >
                <app-icon [name]="plateName() ? 'check-circle' : 'scan-plate'" [size]="22" />
                <strong>{{ plateName() || 'Photo de la plaque' }}</strong>
                <span>{{ plateName() ? 'Fichier prêt à être envoyé' : 'Pour la lecture de plaque' }}</span>
                <input type="file" accept="image/*" (change)="onPlate($event)" />
              </label>
            </div>

            <div class="alert info">
              <app-icon name="info" [size]="16" />
              <span>
                Le signalement sera d'abord qualifié par un agent Quipux, puis validé ou
                refusé par un agent de police.
              </span>
            </div>
          </div>

          <div class="modal-foot">
            <button class="btn ghost" (click)="showForm.set(false)">Annuler</button>
            <button class="btn" (click)="submit()" [disabled]="busy()">
              @if (busy()) {
                <span class="spinner" style="width:15px;height:15px;border-width:2px;border-top-color:#fff"></span>
                Envoi…
              } @else {
                <app-icon name="send" [size]="15" />
                Envoyer le signalement
              }
            </button>
          </div>
        </div>
      </div>
    }
  `,
})
export class InfractionsComponent implements OnInit {
  private readonly service = inject(InfractionService);
  private readonly typeService = inject(InfractionTypeService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  readonly auth = inject(AuthService);

  readonly infractions = signal<Infraction[]>([]);
  readonly types = signal<InfractionType[]>([]);
  readonly loading = signal(false);
  readonly busy = signal(false);
  readonly error = signal<string | null>(null);
  readonly formError = signal<string | null>(null);
  readonly showForm = signal(false);
  readonly selected = signal<Infraction | null>(null);

  readonly tab = signal<Tab>('all');
  readonly search = signal('');
  readonly typeFilter = signal('');

  readonly photoName = signal('');
  readonly videoName = signal('');
  readonly plateName = signal('');

  private photo?: File;
  private video?: File;
  private plate?: File;
  private pendingId: string | null = null;

  readonly isStaff = computed(() => isStaff(this.auth.role()));
  readonly canQualify = computed(() => canQualify(this.auth.role()));
  readonly canValidate = computed(() => canValidate(this.auth.role()));
  readonly canDelete = computed(() => {
    const role = normalizeRole(this.auth.role());
    return role === 'admin' || role === 'superviseur';
  });

  readonly total = computed(() => this.infractions().length);
  readonly counts = computed(() => {
    const result = { pending: 0, constatee: 0, validee: 0, refusee: 0 };
    for (const i of this.infractions()) result[infractionStatus(i)]++;
    return result;
  });

  readonly filtered = computed(() => {
    let items = this.infractions();
    const tab = this.tab();
    if (tab !== 'all') {
      items = items.filter((i) => infractionStatus(i) === tab);
    }
    // Agent police ne voit pas les dossiers en attente de qualification
    if (this.canValidate() && !this.canQualify()) {
      items = items.filter((i) => infractionStatus(i) !== 'pending');
    }
    const q = this.search().trim().toLowerCase();
    if (q) {
      items = items.filter((i) =>
        [
          plateOf(i),
          i.lieu,
          i.adresse,
          i.description,
          i.clientName,
          i.userName,
          this.typeName(i),
        ]
          .filter(Boolean)
          .join(' ')
          .toLowerCase()
          .includes(q),
      );
    }
    const type = this.typeFilter();
    if (type) {
      items = items.filter((i) => (i.typeId ?? i.inciviTypeId) === type);
    }
    return items;
  });

  readonly pageTitle = computed(() => {
    if (this.canQualify() && !this.canValidate()) return 'File Quipux';
    if (this.canValidate() && !this.canQualify()) return 'Validation police';
    return this.isStaff() ? 'Signalements' : 'Mes signalements';
  });

  readonly pageSubtitle = computed(() => {
    if (this.canQualify() && !this.canValidate()) {
      return 'Qualifiez les signalements : confirmez l’infraction ou signalez un dossier non conforme.';
    }
    if (this.canValidate() && !this.canQualify()) {
      return 'Dossiers qualifiés par Quipux en attente de validation ou de refus.';
    }
    return 'Recevez, qualifiez et suivez les signalements photo et vidéo.';
  });

  form = {
    typeId: '',
    plaqueImmatriculation: '',
    lieu: '',
    priority: 'normale',
    latitude: undefined as number | undefined,
    longitude: undefined as number | undefined,
    description: '',
  };

  ngOnInit(): void {
    this.load();
    this.typeService.list().subscribe({
      next: (r) => this.types.set(r.data ?? []),
      error: () => this.types.set([]),
    });
    this.route.queryParamMap.subscribe((params) => {
      const vue = params.get('vue');
      if (vue === 'quipux') this.tab.set('pending');
      else if (vue === 'police') this.tab.set('constatee');
      const q = params.get('q');
      if (q != null) this.search.set(q);
      if (params.get('new') === '1') this.showForm.set(true);
      const id = params.get('id');
      if (id) this.openById(id);
    });
  }

  load(): void {
    this.loading.set(true);
    this.service.list().subscribe({
      next: (r) => {
        this.infractions.set(r.data ?? []);
        this.loading.set(false);
        if (this.pendingId) {
          const found = (r.data ?? []).find((i) => i.id === this.pendingId);
          this.pendingId = null;
          if (found) this.selected.set(found);
        }
      },
      error: () => this.loading.set(false),
    });
  }

  setTab(tab: Tab): void {
    this.tab.set(tab);
  }

  resetFilters(): void {
    this.tab.set('all');
    this.search.set('');
    this.typeFilter.set('');
  }

  open(i: Infraction): void {
    // Agent police ne peut pas ouvrir les dossiers en attente de qualification
    if (this.canValidate() && !this.canQualify() && infractionStatus(i) === 'pending') {
      return;
    }
    this.selected.set(i);
  }

  closeDetail(): void {
    this.selected.set(null);
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { id: null },
      queryParamsHandling: 'merge',
      replaceUrl: true,
    });
  }

  private openById(id: string): void {
    const found = this.infractions().find((i) => i.id === id);
    if (found) {
      // Agent police ne peut pas ouvrir les dossiers en attente de qualification
      if (this.canValidate() && !this.canQualify() && infractionStatus(found) === 'pending') {
        return;
      }
      this.selected.set(found);
    } else {
      this.pendingId = id;
      if (!this.loading()) this.load();
    }
  }

  onUpdated(updated: Infraction): void {
    this.infractions.update((items) =>
      items.map((i) => (i.id === updated.id ? { ...i, ...updated } : i)),
    );
    this.selected.set(updated);
  }

  openForm(): void {
    this.form = {
      typeId: '',
      plaqueImmatriculation: '',
      lieu: '',
      priority: 'normale',
      latitude: undefined,
      longitude: undefined,
      description: '',
    };
    this.photo = this.video = this.plate = undefined;
    this.photoName.set('');
    this.videoName.set('');
    this.plateName.set('');
    this.formError.set(null);
    this.showForm.set(true);
  }

  onBackdrop(event: Event): void {
    if (event.target === event.currentTarget) this.showForm.set(false);
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
  }

  onDrop(event: DragEvent, kind: 'photo' | 'video' | 'plate'): void {
    event.preventDefault();
    const file = event.dataTransfer?.files?.[0];
    if (!file) return;
    if (kind === 'photo') {
      this.photo = file;
      this.photoName.set(file.name);
    } else if (kind === 'video') {
      this.video = file;
      this.videoName.set(file.name);
    } else {
      this.plate = file;
      this.plateName.set(file.name);
    }
  }

  onPhoto(e: Event): void {
    this.photo = (e.target as HTMLInputElement).files?.[0] ?? undefined;
    this.photoName.set(this.photo?.name ?? '');
  }
  onVideo(e: Event): void {
    this.video = (e.target as HTMLInputElement).files?.[0] ?? undefined;
    this.videoName.set(this.video?.name ?? '');
  }
  onPlate(e: Event): void {
    this.plate = (e.target as HTMLInputElement).files?.[0] ?? undefined;
    this.plateName.set(this.plate?.name ?? '');
  }

  submit(): void {
    if (!this.form.typeId) {
      this.formError.set('Veuillez choisir un type d’infraction.');
      return;
    }
    this.busy.set(true);
    this.formError.set(null);
    const fields: Record<string, string> = {
      typeId: this.form.typeId,
      inciviTypeId: this.form.typeId,
      plaqueImmatriculation: this.form.plaqueImmatriculation.trim().toUpperCase(),
      numeroImmatriculation: this.form.plaqueImmatriculation.trim().toUpperCase(),
      lieu: this.form.lieu,
      priority: this.form.priority,
      description: this.form.description,
      latitude: this.form.latitude != null ? String(this.form.latitude) : '',
      longitude: this.form.longitude != null ? String(this.form.longitude) : '',
    };
    const obs =
      this.photo || this.video || this.plate
        ? this.service.createWithFiles(fields, {
            video: this.video,
            photo: this.photo,
            plate: this.plate,
          })
        : this.service.create(fields);

    obs.subscribe({
      next: () => {
        this.busy.set(false);
        this.showForm.set(false);
        this.load();
      },
      error: (e) => {
        this.busy.set(false);
        this.formError.set(e?.error?.message ?? 'Erreur lors de la création du signalement.');
      },
    });
  }

  remove(i: Infraction): void {
    if (!confirm('Supprimer ce signalement ? Cette action est définitive.')) return;
    this.service.delete(i.id).subscribe({
      next: () => {
        if (this.selected()?.id === i.id) this.selected.set(null);
        this.load();
      },
      error: (e) => this.error.set(e?.error?.message ?? 'Suppression impossible.'),
    });
  }

  typeName(i: Infraction): string {
    const id = i.typeId ?? i.inciviTypeId;
    return this.types().find((t) => t.id === id)?.nom ?? id ?? 'Infraction';
  }

  thumb(i: Infraction): string | null {
    const media = mainMedia(i);
    return media.type === 'image' ? media.url : null;
  }

  plateOf = plateOf;
  statusLabel = statusLabel;
  statusTone = statusTone;

  isLockedByOther(i: Infraction): boolean {
    const currentUserId = this.auth.user()?.userId;
    if (!i.lockedByUserId || !currentUserId) return false;
    return i.lockedByUserId !== currentUserId;
  }
}
