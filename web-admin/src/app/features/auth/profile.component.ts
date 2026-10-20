import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/services/auth.service';
import { IconComponent } from '../../shared/icon.component';
import { displayName, initials, roleLabel } from '../../core/roles';

@Component({
  selector: 'app-profile',
  imports: [FormsModule, IconComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Mon compte</span>
        <h1>Mon profil</h1>
        <span class="page-sub">Gérez vos informations personnelles et votre véhicule.</span>
      </div>
    </div>

    <div class="profile-grid">
      <div class="card profile-card">
        <div class="avatar lg">{{ userInitials() }}</div>
        <h2>{{ userName() }}</h2>
        <span class="badge blue">{{ userRole() }}</span>
        <p class="muted small" style="margin-top:0.3rem">{{ auth.user()?.email || '—' }}</p>

        <hr style="width:100%;border:none;border-top:1px solid var(--border);margin:0.8rem 0" />

        <div class="row" style="justify-content:center">
          <span class="chip">
            <app-icon name="phone" [size]="13" />
            {{ auth.user()?.phone || auth.user()?.telephone || 'Non renseigné' }}
          </span>
          @if (auth.user()?.enPanne) {
            <span class="badge danger">En panne</span>
          } @else {
            <span class="badge validee">Actif</span>
          }
        </div>
      </div>

      <div class="stack">
        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Informations personnelles</strong>
              <span>Données associées à votre compte.</span>
            </div>
            <app-icon name="user" [size]="18" />
          </div>
          <div>
            <div class="profile-row">
              <span class="label">Nom complet</span>
              <strong>{{ userName() }}</strong>
            </div>
            <div class="profile-row">
              <span class="label">Email</span>
              <strong>{{ auth.user()?.email || '—' }}</strong>
            </div>
            <div class="profile-row">
              <span class="label">Téléphone</span>
              <strong>{{ auth.user()?.phone || auth.user()?.telephone || '—' }}</strong>
            </div>
            <div class="profile-row">
              <span class="label">Profil</span>
              <strong>{{ userRole() }}</strong>
            </div>
            <div class="profile-row">
              <span class="label">Matricule</span>
              <strong>{{ auth.user()?.matricule || '—' }}</strong>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Plaque d'immatriculation</strong>
              <span>Associez votre véhicule pour suivre vos signalements.</span>
            </div>
            <app-icon name="scan-plate" [size]="18" />
          </div>
          <div class="plate-display">
            @if (auth.user()?.plaqueImmatriculation) {
              <span class="plate-tag">{{ auth.user()?.plaqueImmatriculation }}</span>
            } @else {
              <span class="muted small">Aucune plaque enregistrée.</span>
            }
          </div>
          <div class="plate-editor">
            <input
              type="text"
              [(ngModel)]="plaque"
              placeholder="AB-1234-CD"
              style="text-transform:uppercase"
            />
            <button class="btn sm" (click)="savePlaque()" [disabled]="busy() || !plaque">
              <app-icon name="check" [size]="14" />
              Enregistrer
            </button>
          </div>
        </div>

        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Déclarer une panne</strong>
              <span>Indiquez une période d'indisponibilité de votre véhicule.</span>
            </div>
            <app-icon name="alert" [size]="18" />
          </div>
          <p class="muted small">
            Une panne déclarée suspend temporairement le traitement des signalements liés à
            votre plaque.
          </p>
          <div class="row">
            <button class="btn secondary" (click)="declarePanne()" [disabled]="busy()">
              <app-icon name="alert" [size]="15" />
              Déclarer maintenant
            </button>
            @if (auth.user()?.enPanne) {
              <span class="badge danger">Véhicule en panne</span>
            }
          </div>
        </div>

        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Changer mon mot de passe</strong>
              <span>Sécurisez votre compte en modifiant votre mot de passe.</span>
            </div>
            <app-icon name="lock" [size]="18" />
          </div>
          @if (!showPasswordForm()) {
            <button class="btn secondary" (click)="showPasswordForm.set(true)" [disabled]="busy()">
              <app-icon name="lock" [size]="15" />
              Changer le mot de passe
            </button>
          } @else {
            <div class="stack" style="gap:0.8rem">
              <div>
                <label class="label">Ancien mot de passe</label>
                <input
                  type="password"
                  [(ngModel)]="oldPassword"
                  placeholder="••••••••"
                  [disabled]="busy()"
                />
              </div>
              <div>
                <label class="label">Nouveau mot de passe</label>
                <input
                  type="password"
                  [(ngModel)]="newPassword"
                  placeholder="••••••••"
                  [disabled]="busy()"
                />
              </div>
              <div>
                <label class="label">Confirmer le nouveau mot de passe</label>
                <input
                  type="password"
                  [(ngModel)]="confirmPassword"
                  placeholder="••••••••"
                  [disabled]="busy()"
                />
              </div>
              <div class="row">
                <button class="btn" (click)="changePassword()" [disabled]="busy() || !isPasswordValid()">
                  <app-icon name="check" [size]="14" />
                  Confirmer
                </button>
                <button class="btn secondary" (click)="cancelPasswordChange()" [disabled]="busy()">
                  Annuler
                </button>
              </div>
            </div>
          }
        </div>

        @if (message()) {
          <div class="alert ok">
            <app-icon name="check-circle" [size]="16" />
            <span>{{ message() }}</span>
          </div>
        }
      </div>
    </div>
  `,
})
export class ProfileComponent {
  readonly auth = inject(AuthService);
  readonly busy = signal(false);
  readonly message = signal<string | null>(null);
  readonly userName = computed(() => displayName(this.auth.user()));
  readonly userInitials = computed(() => initials(this.auth.user()));
  readonly userRole = computed(() => roleLabel(this.auth.role()));
  plaque = this.auth.user()?.plaqueImmatriculation ?? '';
  readonly showPasswordForm = signal(false);
  oldPassword = '';
  newPassword = '';
  confirmPassword = '';

  savePlaque(): void {
    if (!this.plaque) return;
    this.busy.set(true);
    this.auth.updatePlaque(this.plaque).subscribe({
      next: () => {
        this.busy.set(false);
        this.message.set('Plaque enregistrée.');
        this.auth.me().subscribe();
      },
      error: (e) => {
        this.busy.set(false);
        this.message.set(e?.error?.message ?? 'Erreur.');
      },
    });
  }

  declarePanne(): void {
    this.busy.set(true);
    this.auth.declarePanne().subscribe({
      next: () => {
        this.busy.set(false);
        this.message.set('Panne déclarée.');
        this.auth.me().subscribe();
      },
      error: (e) => {
        this.busy.set(false);
        this.message.set(e?.error?.message ?? 'Erreur.');
      },
    });
  }

  isPasswordValid(): boolean {
    return (
      this.oldPassword.length > 0 &&
      this.newPassword.length >= 6 &&
      this.newPassword === this.confirmPassword
    );
  }

  changePassword(): void {
    if (!this.isPasswordValid()) return;
    this.busy.set(true);
    this.auth.changePassword(this.oldPassword, this.newPassword).subscribe({
      next: () => {
        this.busy.set(false);
        this.message.set('Mot de passe modifié avec succès.');
        this.cancelPasswordChange();
      },
      error: (e) => {
        this.busy.set(false);
        this.message.set(e?.error?.message ?? 'Erreur lors du changement de mot de passe.');
      },
    });
  }

  cancelPasswordChange(): void {
    this.showPasswordForm.set(false);
    this.oldPassword = '';
    this.newPassword = '';
    this.confirmPassword = '';
  }
}
