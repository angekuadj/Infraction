import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { IconComponent } from '../../shared/icon.component';

@Component({
  selector: 'app-register',
  imports: [FormsModule, RouterLink, IconComponent],
  template: `
    <div class="auth">
      <aside class="auth-aside">
        <div class="auth-brand">
          <div class="brand-mark">
            <app-icon name="shield" [size]="24" />
          </div>
          <div>
            <strong>Circulation</strong>
            <span>Plateforme de contrôle</span>
          </div>
        </div>

        <div class="auth-hero">
          <h2>Signalez les infractions autour de vous.</h2>
          <p>
            Créez votre compte utilisateur en quelques secondes et contribuez à la
            sécurité routière de votre commune.
          </p>

          <div class="auth-features">
            <div class="auth-feature">
              <div class="feat-icon"><app-icon name="camera" [size]="17" /></div>
              <div>
                <strong>Signalement photo & vidéo</strong>
                <span>Preuves horodatées et géolocalisées.</span>
              </div>
            </div>
            <div class="auth-feature">
              <div class="feat-icon"><app-icon name="id-card" [size]="17" /></div>
              <div>
                <strong>Identité vérifiée</strong>
                <span>Numéro de CNI et pièce justificative.</span>
              </div>
            </div>
            <div class="auth-feature">
              <div class="feat-icon"><app-icon name="message" [size]="17" /></div>
              <div>
                <strong>Assistance réactive</strong>
                <span>Suivi de vos réclamations jusqu'à clôture.</span>
              </div>
            </div>
          </div>
        </div>

        <div class="auth-foot">© {{ year }} Circulation — Tous droits réservés.</div>
      </aside>

      <main class="auth-main">
        <div class="auth-card" style="max-width:460px">
          <div>
            <div class="eyebrow">Création de compte</div>
            <h1>Inscription utilisateur</h1>
          </div>
          <p class="auth-sub">
            Profil <strong>Utilisateur</strong>. Les autres profils sont créés par un administrateur.
          </p>

          <form (ngSubmit)="submit()">
            <label>
              Nom complet
              <input type="text" name="nom" [(ngModel)]="nom" placeholder="Awa Coulibaly" required />
            </label>

            <label>
              Numéro de téléphone
              <input
                type="tel"
                name="phone"
                [(ngModel)]="phone"
                placeholder="+225 00 00 00 00"
                required
              />
              <span class="help">Ce numéro servira d'identifiant de connexion.</span>
            </label>

            <label>
              Numéro de CNI
              <input type="text" name="cni" [(ngModel)]="cni" placeholder="CI000123456789" required />
            </label>

            <label>
              Photo de la CNI <span class="help" style="display:inline">(optionnel)</span>
              <input type="file" accept="image/*" (change)="onPhoto($event)" />
            </label>

            @if (photoName()) {
              <div class="alert" style="background:var(--surface-2);color:var(--text)">
                <app-icon name="check" [size]="16" />
                <span>{{ photoName() }}</span>
              </div>
            }

            <label>
              Mot de passe
              <input
                type="password"
                name="password"
                [(ngModel)]="password"
                placeholder="6 caractères minimum"
                required
                autocomplete="new-password"
              />
              <span class="help">Utilisez au moins 6 caractères.</span>
            </label>

            @if (error()) {
              <div class="alert">
                <app-icon name="alert" [size]="16" />
                <span>{{ error() }}</span>
              </div>
            }

            <button type="submit" class="btn block" [disabled]="loading()">
              @if (loading()) {
                <span class="spinner" style="width:16px;height:16px;border-width:2px;border-top-color:#fff"></span>
                Création…
              } @else {
                Créer mon compte
                <app-icon name="arrow-right" [size]="16" />
              }
            </button>
          </form>

          <p class="muted small" style="text-align:center">
            Déjà un compte ? <a routerLink="/login">Se connecter</a>
          </p>
        </div>
      </main>
    </div>
  `,
})
export class RegisterComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  nom = '';
  phone = '';
  cni = '';
  password = '';
  photo: File | null = null;

  readonly photoName = signal<string | null>(null);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly year = new Date().getFullYear();

  onPhoto(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    this.photo = file;
    this.photoName.set(file ? file.name : null);
  }

  submit(): void {
    this.loading.set(true);
    this.error.set(null);
    this.auth
      .register(
        {
          nom: this.nom,
          phone: this.phone,
          cni: this.cni,
          password: this.password,
        },
        this.photo,
      )
      .subscribe({
        next: () => {
          this.loading.set(false);
          this.router.navigateByUrl('/dashboard');
        },
        error: (err) => {
          this.loading.set(false);
          this.error.set(err?.error?.message ?? "Échec de l'inscription.");
        },
      });
  }
}
