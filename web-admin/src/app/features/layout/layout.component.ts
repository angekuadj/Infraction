import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NavigationEnd, Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { filter, map } from 'rxjs';
import { AuthService } from '../../core/services/auth.service';
import { IconComponent } from '../../shared/icon.component';
import {
  canManageUsers,
  canQualify,
  canValidate,
  displayName,
  initials,
  isStaff,
  roleLabel,
} from '../../core/roles';

const PAGE_TITLES: Record<string, string> = {
  dashboard: 'Tableau de bord',
  signalements: 'Signalements',
  reclamations: 'Réclamations',
  notifications: 'Notifications',
  rapports: 'Rapports & statistiques',
  wallet: 'Portefeuille',
  profil: 'Mon profil',
  utilisateurs: 'Équipe & accès',
};

@Component({
  selector: 'app-layout',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, IconComponent, FormsModule],
  template: `
    <div class="shell" [class.nav-open]="navOpen()">
      <div class="sidebar-overlay" (click)="navOpen.set(false)"></div>

      <aside class="sidebar">
        <div class="sidebar-brand">
          <div class="brand-mark">
            <app-icon name="shield" [size]="22" />
          </div>
          <div class="brand-text">
            <strong>Circulation</strong>
            <span>Plateforme de contrôle</span>
          </div>
        </div>

        <div class="nav-scroll">
          <div class="nav-group">
            <div class="nav-label">Pilotage</div>
            <a
              class="nav-link"
              routerLink="/dashboard"
              routerLinkActive="active"
              [routerLinkActiveOptions]="{ exact: true }"
              (click)="closeNav()"
            >
              <app-icon name="dashboard" [size]="18" />
              Tableau de bord
            </a>
            <a
              class="nav-link"
              routerLink="/signalements"
              routerLinkActive="active"
              (click)="closeNav()"
            >
              <app-icon name="reports" [size]="18" />
              Signalements
            </a>
            @if (staff()) {
              <a class="nav-link" routerLink="/rapports" routerLinkActive="active" (click)="closeNav()">
                <app-icon name="chart" [size]="18" />
                Rapports & statistiques
              </a>
            }
          </div>

          @if (qualify() || validate()) {
            <div class="nav-group">
              <div class="nav-label">Traitement</div>
              @if (qualify()) {
                <a
                  class="nav-link"
                  routerLink="/signalements"
                  [queryParams]="{ vue: 'quipux' }"
                  (click)="closeNav()"
                >
                  <app-icon name="scan-plate" [size]="18" />
                  File Quipux
                </a>
              }
              @if (validate()) {
                <a
                  class="nav-link"
                  routerLink="/signalements"
                  [queryParams]="{ vue: 'police' }"
                  (click)="closeNav()"
                >
                  <app-icon name="shield" [size]="18" />
                  Validation police
                </a>
              }
            </div>
          }

          <div class="nav-group">
            <div class="nav-label">Assistance</div>
            <a class="nav-link" routerLink="/reclamations" routerLinkActive="active" (click)="closeNav()">
              <app-icon name="headset" [size]="18" />
              Réclamations
            </a>
            <a class="nav-link" routerLink="/notifications" routerLinkActive="active" (click)="closeNav()">
              <app-icon name="bell" [size]="18" />
              Notifications
            </a>
          </div>

          @if (manageUsers()) {
            <div class="nav-group">
              <div class="nav-label">Administration</div>
              <a class="nav-link" routerLink="/utilisateurs" routerLinkActive="active" (click)="closeNav()">
                <app-icon name="users" [size]="18" />
                Équipe & accès
              </a>
            </div>
          }

          <div class="nav-group">
            <div class="nav-label">Mon compte</div>
            <a class="nav-link" routerLink="/wallet" routerLinkActive="active" (click)="closeNav()">
              <app-icon name="wallet" [size]="18" />
              Portefeuille
            </a>
            <a class="nav-link" routerLink="/profil" routerLinkActive="active" (click)="closeNav()">
              <app-icon name="user" [size]="18" />
              Mon profil
            </a>
          </div>
        </div>

        <div class="sidebar-user">
          <div class="avatar dark">{{ userInitials() }}</div>
          <div class="user-meta">
            <div class="user-name">{{ userName() }}</div>
            <div class="user-role">{{ userRole() }}</div>
          </div>
          <button class="sidebar-logout" (click)="auth.logout()" title="Se déconnecter">
            <app-icon name="logout" [size]="17" />
          </button>
        </div>
      </aside>

      <div class="main">
        <header class="topbar">
          <button class="icon-btn menu-btn" (click)="navOpen.set(true)" aria-label="Ouvrir le menu">
            <app-icon name="menu" [size]="20" />
          </button>

          <div class="breadcrumb">
            <span>Circulation</span>
            <app-icon class="sep" name="chevron-right" [size]="13" />
            <span class="current">{{ pageTitle() }}</span>
          </div>

          <form class="search-input topbar-search" (ngSubmit)="search()">
            <app-icon name="search" [size]="16" />
            <input
              type="search"
              name="q"
              [(ngModel)]="searchTerm"
              placeholder="Rechercher une plaque, un lieu…"
              aria-label="Rechercher"
            />
          </form>

          <div class="topbar-actions">
            <a class="icon-btn bell" routerLink="/notifications" title="Notifications">
              <app-icon name="bell" [size]="19" />
              <span class="dot"></span>
            </a>
            <a class="topbar-user" routerLink="/profil">
              <div class="avatar sm">{{ userInitials() }}</div>
              <div class="user-meta">
                <div class="user-name">{{ userName() }}</div>
                <div class="user-role">{{ userRole() }}</div>
              </div>
              <app-icon name="chevron-down" [size]="14" />
            </a>
          </div>
        </header>

        <main class="page">
          <router-outlet />
        </main>
      </div>
    </div>
  `,
})
export class LayoutComponent {
  readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  readonly navOpen = signal(false);
  readonly staff = computed(() => isStaff(this.auth.role()));
  readonly qualify = computed(() => canQualify(this.auth.role()));
  readonly validate = computed(() => canValidate(this.auth.role()));
  readonly manageUsers = computed(() => canManageUsers(this.auth.role()));

  readonly userName = computed(() => displayName(this.auth.user()));
  readonly userInitials = computed(() => initials(this.auth.user()));
  readonly userRole = computed(() => roleLabel(this.auth.role()));

  searchTerm = '';

  readonly pageTitle = toSignal(
    this.router.events.pipe(
      filter((event) => event instanceof NavigationEnd),
      map(() => this.titleFor(this.router.url)),
    ),
    { initialValue: this.titleFor(this.router.url) },
  );

  closeNav(): void {
    this.navOpen.set(false);
  }

  search(): void {
    const q = this.searchTerm.trim();
    this.router.navigate(['/signalements'], q ? { queryParams: { q } } : {});
    this.searchTerm = '';
    this.closeNav();
  }

  private titleFor(url: string): string {
    const segment = url.split('?')[0].split('/').filter(Boolean)[0] ?? 'dashboard';
    return PAGE_TITLES[segment] ?? 'Tableau de bord';
  }
}
