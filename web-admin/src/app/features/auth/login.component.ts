import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { IconComponent } from '../../shared/icon.component';

@Component({
  selector: 'app-login',
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
          <h2>Chaque signalement compte pour une circulation plus sûre.</h2>
          <p>
            Centralisez les signalements photo et vidéo, qualifiez les infractions et
            coordonnez la validation avec les agents de police.
          </p>

          <div class="auth-features">
            <div class="auth-feature">
              <div class="feat-icon"><app-icon name="scan-plate" [size]="17" /></div>
              <div>
                <strong>Lecture et anonymisation des plaques</strong>
                <span>Identifiez les véhicules et masquez les données sensibles.</span>
              </div>
            </div>
            <div class="auth-feature">
              <div class="feat-icon"><app-icon name="layers" [size]="17" /></div>
              <div>
                <strong>Workflow Quipux → Police</strong>
                <span>Qualification, validation et suivi en temps réel.</span>
              </div>
            </div>
            <div class="auth-feature">
              <div class="feat-icon"><app-icon name="headset" [size]="17" /></div>
              <div>
                <strong>Service client intégré</strong>
                <span>Réclamations et messagerie centralisées.</span>
              </div>
            </div>
          </div>
        </div>

        <div class="auth-foot">© {{ year }} Circulation — Tous droits réservés.</div>
      </aside>

      <main class="auth-main">
        <div class="auth-card">
          <div>
            <div class="eyebrow">Espace sécurisé</div>
            <h1>Connexion</h1>
          </div>
          <p class="auth-sub">Accédez à votre espace de traitement et de suivi.</p>

          <form (ngSubmit)="submit()">
            <label>
              Email ou téléphone
              <input
                type="text"
                name="identifier"
                [(ngModel)]="identifier"
                placeholder="agent@circulation.ci"
                required
                autocomplete="username"
              />
            </label>

            <label>
              Mot de passe
              <div class="search-input">
                <input
                  [type]="showPassword() ? 'text' : 'password'"
                  name="password"
                  [(ngModel)]="password"
                  placeholder="••••••••"
                  required
                  autocomplete="current-password"
                />
                <button
                  type="button"
                  class="btn ghost icon sm"
                  style="position:absolute; right:4px;"
                  (click)="showPassword.set(!showPassword())"
                  [attr.aria-label]="showPassword() ? 'Masquer' : 'Afficher'"
                >
                  <app-icon [name]="showPassword() ? 'eye-off' : 'eye'" [size]="16" />
                </button>
              </div>
            </label>

            @if (error()) {
              <div class="alert">
                <app-icon name="alert" [size]="16" />
                <span>{{ error() }}</span>
              </div>
            }

            <button type="submit" class="btn block" [disabled]="loading() || !identifier || !password">
              @if (loading()) {
                <span class="spinner" style="width:16px;height:16px;border-width:2px;border-top-color:#fff"></span>
                Connexion…
              } @else {
                Se connecter
                <app-icon name="arrow-right" [size]="16" />
              }
            </button>
          </form>

          <div class="auth-divider">Nouveau sur la plateforme ?</div>

          <p class="muted small" style="text-align:center">
            <a routerLink="/register">Créer un compte usager</a> — les comptes agents sont
            créés par un administrateur.
          </p>
        </div>
      </main>
    </div>
  `,
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  identifier = '';
  password = '';
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly showPassword = signal(false);
  readonly year = new Date().getFullYear();

  submit(): void {
    if (!this.identifier || !this.password) return;
    this.loading.set(true);
    this.error.set(null);
    this.auth.login({ identifier: this.identifier, password: this.password }).subscribe({
      next: () => {
        this.loading.set(false);
        this.router.navigateByUrl('/dashboard');
      },
      error: (err) => {
        this.loading.set(false);
        this.error.set(err?.error?.message ?? 'Échec de la connexion.');
      },
    });
  }
}
