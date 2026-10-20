import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { UserService } from '../../core/services/user.service';
import { ApiRole, User } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';
import {
  ROLE_OPTIONS,
  displayName,
  initials,
  isCitizen,
  isStaff,
  normalizeRole,
  roleLabel,
} from '../../core/roles';

const AGENT_ROLES: ApiRole[] = ['agent_quipux', 'agent_police', 'police_terrain'];

@Component({
  selector: 'app-users',
  imports: [FormsModule, DatePipe, IconComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Administration</span>
        <h1>Équipe & accès</h1>
        <span class="page-sub">
          Créez les comptes, attribuez les profils et contrôlez les accès à la plateforme.
        </span>
      </div>
      <div class="btn-group">
        <button class="btn secondary" (click)="load()" [disabled]="loading()">
          <app-icon name="refresh" [size]="16" />
          Actualiser
        </button>
        <button class="btn" (click)="openForm()">
          <app-icon name="plus" [size]="16" />
          Créer un compte
        </button>
      </div>
    </div>

    @if (error()) {
      <div class="alert section">
        <app-icon name="alert" [size]="16" />
        <span>{{ error() }}</span>
      </div>
    }

    <div class="kpi-grid">
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Comptes totaux</span>
          <div class="kpi-icon"><app-icon name="users" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ users().length }}</div>
        <div class="kpi-foot"><span>inscrits sur la plateforme</span></div>
      </div>
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Équipe interne</span>
          <div class="kpi-icon violet"><app-icon name="shield" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ staffCount() }}</div>
        <div class="kpi-foot"><span>agents et superviseurs</span></div>
      </div>
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Citoyens</span>
          <div class="kpi-icon green"><app-icon name="user" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ citizenCount() }}</div>
        <div class="kpi-foot"><span>utilisateurs & propriétaires</span></div>
      </div>
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Comptes désactivés</span>
          <div class="kpi-icon red"><app-icon name="lock" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ inactiveCount() }}</div>
        <div class="kpi-foot"><span>accès suspendu</span></div>
      </div>
    </div>

    <div class="card flush">
      <div class="toolbar" style="padding:1rem 1.25rem">
        <div class="search-input">
          <app-icon name="search" [size]="16" />
          <input
            type="search"
            [ngModel]="search()"
            (ngModelChange)="search.set($event)"
            placeholder="Rechercher un nom, un email, une CNI…"
          />
        </div>
        <select
          class="input"
          style="max-width:220px"
          [ngModel]="roleFilter()"
          (ngModelChange)="roleFilter.set($event)"
          aria-label="Filtrer par profil"
        >
          <option value="">Tous les profils</option>
          @for (r of roleOptions; track r) {
            <option [value]="r">{{ roleLabel(r) }}</option>
          }
        </select>
        <div class="spacer"></div>
        <span class="muted small">{{ filtered().length }} compte(s)</span>
      </div>

      @if (loading()) {
        <div class="loading"><span class="spinner"></span> Chargement de l'équipe…</div>
      } @else {
        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>Utilisateur</th>
                <th>Contact</th>
                <th>Profil</th>
                <th>Matricule / Plaque / CNI</th>
                <th>Statut</th>
                <th>Inscription</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              @for (u of filtered(); track u.id) {
                <tr>
                  <td>
                    <div class="user-cell">
                      <div class="avatar sm">{{ initials(u) }}</div>
                      <div>
                        <div class="cell-main">{{ displayName(u) }}</div>
                        <div class="cell-sub">{{ u.email || '—' }}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div>{{ u.phone || u.telephone || '—' }}</div>
                    <div class="cell-sub">{{ u.enPanne ? 'Véhicule en panne' : 'Disponible' }}</div>
                  </td>
                  <td>
                    <select
                      class="input"
                      style="padding:0.35rem 1.8rem 0.35rem 0.55rem;font-size:0.8rem;max-width:180px"
                      [ngModel]="normalize(u.role)"
                      (ngModelChange)="changeRole(u, $event)"
                      [disabled]="busyId() === u.id"
                      aria-label="Profil"
                    >
                      @for (r of roleOptions; track r) {
                        <option [value]="r">{{ roleLabel(r) }}</option>
                      }
                    </select>
                  </td>
                  <td>
                    <div class="mono small">{{ u.matricule || '—' }}</div>
                    @if (u.plaqueImmatriculation) {
                      <span class="plate-tag" style="margin-top:3px">{{ u.plaqueImmatriculation }}</span>
                    }
                    <div class="cell-sub" style="margin-top:3px">CNI : {{ u.cni || '—' }}</div>
                  </td>
                  <td>
                    @if (isActive(u)) {
                      <span class="badge validee">Actif</span>
                    } @else {
                      <span class="badge refusee">Désactivé</span>
                    }
                  </td>
                  <td class="muted small nowrap">
                    {{ u.createdAt ? (u.createdAt | date: 'dd/MM/yyyy') : '—' }}
                  </td>
                  <td>
                    <div class="row" style="gap:0.5rem">
                      <button
                        class="btn sm"
                        [class.ghost]="isActive(u)"
                        [class.danger-soft]="!isActive(u)"
                        (click)="toggleActive(u)"
                        [disabled]="busyId() === u.id"
                      >
                        <app-icon [name]="isActive(u) ? 'lock' : 'check'" [size]="14" />
                        {{ isActive(u) ? 'Désactiver' : 'Réactiver' }}
                      </button>
                      <button
                        class="btn sm ghost"
                        (click)="openPasswordForm(u)"
                        [disabled]="busyId() === u.id"
                        title="Changer le mot de passe"
                      >
                        <app-icon name="key" [size]="14" />
                      </button>
                    </div>
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="7">
                    <div class="empty">
                      <div class="empty-icon"><app-icon name="users" [size]="22" /></div>
                      <strong>Aucun utilisateur trouvé</strong>
                      <p>Aucun compte ne correspond à vos filtres.</p>
                    </div>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      }
    </div>

    @if (showForm()) {
      <div class="modal-backdrop" (click)="onBackdrop($event)">
        <div class="modal wide" (click)="$event.stopPropagation()">
          <div class="modal-head">
            <div class="drawer-title">
              <span class="eyebrow">Nouveau compte</span>
              <h2>Créer un profil</h2>
              <span class="muted small">
                Les profils internes et propriétaires sont créés par l'administration.
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
                Nom
                <input type="text" [(ngModel)]="form.nom" placeholder="Coulibaly" />
              </label>
              <label>
                Prénom
                <input type="text" [(ngModel)]="form.prenom" placeholder="Awa" />
              </label>
              <label>
                Email
                <input type="email" [(ngModel)]="form.email" placeholder="nom@exemple.ci" />
              </label>
              <label>
                Téléphone
                <input type="tel" [(ngModel)]="form.phone" placeholder="+225 00 00 00 00" />
              </label>
              <label>
                Profil
                <select [(ngModel)]="form.role">
                  @for (r of roleOptions; track r) {
                    <option [value]="r">{{ roleLabel(r) }}</option>
                  }
                </select>
              </label>
              <label>
                Mot de passe
                <input
                  type="password"
                  [(ngModel)]="form.password"
                  placeholder="6 caractères minimum"
                  autocomplete="new-password"
                />
              </label>
            </div>

            @if (isAgentRole(form.role)) {
              <label>
                Matricule professionnel
                <input type="text" [(ngModel)]="form.matricule" />
              </label>
            }

            @if (isCitizen(form.role)) {
              <label>
                Plaque d'immatriculation
                <input
                  type="text"
                  [(ngModel)]="form.plaqueImmatriculation"
                  placeholder="AB-1234-CD"
                  style="text-transform:uppercase"
                />
              </label>
            }

            <div class="form-grid">
              <label>
                Numéro de CNI
                <input type="text" [(ngModel)]="form.cni" placeholder="CI000123456789" />
              </label>
              <label class="dropzone" [class.filled]="!!photoName()">
                <app-icon [name]="photoName() ? 'check-circle' : 'id-card'" [size]="22" />
                <strong>{{ photoName() || 'Photo de la CNI' }}</strong>
                <span>{{ photoName() ? 'Fichier prêt à être envoyé' : 'Cliquez pour joindre une image' }}</span>
                <input type="file" accept="image/*" (change)="onPhoto($event)" />
              </label>
            </div>
          </div>

          <div class="modal-foot">
            <button class="btn ghost" (click)="showForm.set(false)">Annuler</button>
            <button class="btn" (click)="submit()" [disabled]="busy()">
              @if (busy()) {
                <span class="spinner" style="width:15px;height:15px;border-width:2px;border-top-color:#fff"></span>
                Création…
              } @else {
                <app-icon name="plus" [size]="15" />
                Créer le compte
              }
            </button>
          </div>
        </div>
      </div>
    }

    @if (showPasswordModal()) {
      <div class="modal-backdrop" (click)="onPasswordBackdrop($event)">
        <div class="modal" (click)="$event.stopPropagation()">
          <div class="modal-head">
            <div class="drawer-title">
              <span class="eyebrow">Sécurité</span>
              <h2>Changer le mot de passe</h2>
              <span class="muted small">
                Utilisateur : {{ displayName(passwordUser()) }}
              </span>
            </div>
            <button class="icon-btn" (click)="closePasswordModal()" aria-label="Fermer">
              <app-icon name="x" [size]="18" />
            </button>
          </div>

          <div class="modal-body">
            @if (passwordError()) {
              <div class="alert">
                <app-icon name="alert" [size]="16" />
                <span>{{ passwordError() }}</span>
              </div>
            }

            <label>
              Nouveau mot de passe
              <input
                type="password"
                [(ngModel)]="newPassword"
                placeholder="6 caractères minimum"
                autocomplete="new-password"
              />
            </label>
          </div>

          <div class="modal-foot">
            <button class="btn ghost" (click)="closePasswordModal()">Annuler</button>
            <button class="btn" (click)="submitPassword()" [disabled]="busy() || newPassword.length < 6">
              @if (busy()) {
                <span class="spinner" style="width:15px;height:15px;border-width:2px;border-top-color:#fff"></span>
                Modification…
              } @else {
                <app-icon name="check" [size]="15" />
                Confirmer
              }
            </button>
          </div>
        </div>
      </div>
    }
  `,
})
export class UsersComponent implements OnInit {
  private readonly service = inject(UserService);
  readonly users = signal<User[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly busyId = signal<string | null>(null);
  readonly search = signal('');
  readonly roleFilter = signal('');

  readonly showForm = signal(false);
  readonly busy = signal(false);
  readonly formError = signal<string | null>(null);
  readonly photoName = signal<string | null>(null);
  photo: File | null = null;

  readonly showPasswordModal = signal(false);
  readonly passwordUser = signal<User | null>(null);
  readonly passwordError = signal<string | null>(null);
  newPassword = '';

  form = {
    nom: '',
    prenom: '',
    email: '',
    phone: '',
    password: '',
    role: 'user' as ApiRole,
    cni: '',
    matricule: '',
    plaqueImmatriculation: '',
  };

  readonly roleOptions = ROLE_OPTIONS;
  displayName = displayName;
  initials = initials;
  roleLabel = roleLabel;
  normalize = normalizeRole;
  isCitizen = isCitizen;

  readonly staffCount = computed(() => this.users().filter((u) => isStaff(u.role)).length);
  readonly citizenCount = computed(() => this.users().filter((u) => isCitizen(u.role)).length);
  readonly inactiveCount = computed(() => this.users().filter((u) => !this.isActive(u)).length);

  readonly filtered = computed(() => {
    let items = this.users();
    const q = this.search().trim().toLowerCase();
    if (q) {
      items = items.filter((u) =>
        [displayName(u), u.email, u.phone, u.telephone, u.matricule, u.plaqueImmatriculation, u.cni]
          .filter(Boolean)
          .join(' ')
          .toLowerCase()
          .includes(q),
      );
    }
    const role = this.roleFilter();
    if (role) items = items.filter((u) => normalizeRole(u.role) === role);
    return items;
  });

  ngOnInit(): void {
    this.load();
  }

  isActive(user: User): boolean {
    return !(user.isActive === false || user.active === false);
  }

  isAgentRole(role?: string): boolean {
    return AGENT_ROLES.includes(normalizeRole(role) as ApiRole);
  }

  load(): void {
    this.loading.set(true);
    this.error.set(null);
    this.service.list().subscribe({
      next: (r) => {
        this.users.set(r.data ?? []);
        this.loading.set(false);
      },
      error: (e) => {
        this.loading.set(false);
        this.error.set(e?.error?.message ?? 'Impossible de charger la liste des utilisateurs.');
      },
    });
  }

  openForm(): void {
    this.form = {
      nom: '',
      prenom: '',
      email: '',
      phone: '',
      password: '',
      role: 'user',
      cni: '',
      matricule: '',
      plaqueImmatriculation: '',
    };
    this.photo = null;
    this.photoName.set(null);
    this.formError.set(null);
    this.showForm.set(true);
  }

  onBackdrop(event: MouseEvent): void {
    if (event.target === event.currentTarget) this.showForm.set(false);
  }

  onPhoto(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0] ?? null;
    this.photo = file;
    this.photoName.set(file ? file.name : null);
  }

  submit(): void {
    if (!this.form.nom.trim()) {
      this.formError.set('Le nom est obligatoire.');
      return;
    }
    if (!this.form.phone.trim()) {
      this.formError.set('Le numéro de téléphone est obligatoire.');
      return;
    }
    if (this.form.password.length < 6) {
      this.formError.set('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }
    if (this.isAgentRole(this.form.role) && !this.form.matricule.trim()) {
      this.formError.set('Le matricule est obligatoire pour un agent.');
      return;
    }

    this.busy.set(true);
    this.formError.set(null);
    this.service.create(this.form, this.photo).subscribe({
      next: (res) => {
        this.busy.set(false);
        this.users.update((items) => [res.data, ...items]);
        this.showForm.set(false);
      },
      error: (e) => {
        this.busy.set(false);
        this.formError.set(e?.error?.message ?? 'Création du compte impossible.');
      },
    });
  }

  changeRole(user: User, role: string): void {
    this.busyId.set(user.id);
    this.service.setRole(user.id, role).subscribe({
      next: () => {
        this.users.update((items) => items.map((u) => (u.id === user.id ? { ...u, role } : u)));
        this.busyId.set(null);
      },
      error: (e) => {
        this.busyId.set(null);
        this.error.set(e?.error?.message ?? 'Modification du profil impossible.');
      },
    });
  }

  toggleActive(user: User): void {
    const active = !this.isActive(user);
    this.busyId.set(user.id);
    this.service.setActive(user.id, active).subscribe({
      next: () => {
        this.users.update((items) =>
          items.map((u) => (u.id === user.id ? { ...u, isActive: active, active } : u)),
        );
        this.busyId.set(null);
      },
      error: (e) => {
        this.busyId.set(null);
        this.error.set(e?.error?.message ?? 'Modification du statut impossible.');
      },
    });
  }

  openPasswordForm(user: User): void {
    this.passwordUser.set(user);
    this.newPassword = '';
    this.passwordError.set(null);
    this.showPasswordModal.set(true);
  }

  closePasswordModal(): void {
    this.showPasswordModal.set(false);
    this.passwordUser.set(null);
    this.newPassword = '';
    this.passwordError.set(null);
  }

  onPasswordBackdrop(event: MouseEvent): void {
    if (event.target === event.currentTarget) this.closePasswordModal();
  }

  submitPassword(): void {
    const user = this.passwordUser();
    if (!user || this.newPassword.length < 6) return;

    this.busy.set(true);
    this.passwordError.set(null);
    this.service.changePassword(user.id, this.newPassword).subscribe({
      next: () => {
        this.busy.set(false);
        this.closePasswordModal();
        this.error.set(null);
      },
      error: (e) => {
        this.busy.set(false);
        this.passwordError.set(e?.error?.message ?? 'Modification du mot de passe impossible.');
      },
    });
  }
}
