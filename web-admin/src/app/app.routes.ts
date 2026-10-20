import { Routes } from '@angular/router';
import { authGuard, guestGuard, managerGuard } from './core/guards/auth.guard';

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
  {
    path: 'login',
    canActivate: [guestGuard],
    loadComponent: () => import('./features/auth/login.component').then((m) => m.LoginComponent),
  },
  {
    path: 'register',
    canActivate: [guestGuard],
    loadComponent: () => import('./features/auth/register.component').then((m) => m.RegisterComponent),
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./features/layout/layout.component').then((m) => m.LayoutComponent),
    children: [
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
      },
      {
        path: 'signalements',
        loadComponent: () =>
          import('./features/infractions/infractions.component').then((m) => m.InfractionsComponent),
      },
      {
        path: 'reclamations',
        loadComponent: () => import('./features/support/support.component').then((m) => m.SupportComponent),
      },
      {
        path: 'notifications',
        loadComponent: () =>
          import('./features/notifications/notifications.component').then((m) => m.NotificationsComponent),
      },
      {
        path: 'rapports',
        loadComponent: () => import('./features/reports/reports.component').then((m) => m.ReportsComponent),
      },
      {
        path: 'wallet',
        loadComponent: () => import('./features/wallet/wallet.component').then((m) => m.WalletComponent),
      },
      {
        path: 'profil',
        loadComponent: () => import('./features/auth/profile.component').then((m) => m.ProfileComponent),
      },
      {
        path: 'utilisateurs',
        canActivate: [managerGuard],
        loadComponent: () => import('./features/users/users.component').then((m) => m.UsersComponent),
      },
      {
        path: 'archives',
        canActivate: [managerGuard],
        loadComponent: () => import('./features/archives/archives.component').then((m) => m.ArchivesComponent),
      },
    ],
  },
  { path: 'infractions', redirectTo: 'signalements' },
  { path: 'support', redirectTo: 'reclamations' },
  { path: 'profile', redirectTo: 'profil' },
  { path: '**', redirectTo: 'dashboard' },
];
