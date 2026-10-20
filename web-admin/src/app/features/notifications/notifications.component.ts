import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { NotificationService } from '../../core/services/notification.service';
import { AppNotification } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';

@Component({
  selector: 'app-notifications',
  imports: [DatePipe, IconComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Activité</span>
        <h1>Notifications</h1>
        <span class="page-sub">
          Suivez les mises à jour de vos signalements et de vos réclamations.
        </span>
      </div>
      <div class="btn-group">
        <div class="segmented">
          <button [class.active]="!unreadOnly()" (click)="setUnread(false)">Toutes</button>
          <button [class.active]="unreadOnly()" (click)="setUnread(true)">
            Non lues ({{ unreadCount() }})
          </button>
        </div>
        <button class="btn secondary" (click)="markAll()">
          <app-icon name="check" [size]="15" />
          Tout marquer comme lu
        </button>
      </div>
    </div>

    @if (loading()) {
      <div class="loading"><span class="spinner"></span> Chargement…</div>
    } @else {
      <div class="list">
        @for (n of items(); track n.id) {
          <div class="notif" [class.unread]="!n.read">
            <div class="notif-icon" [style.background]="iconBg(n)" [style.color]="iconColor(n)">
              <app-icon [name]="iconFor(n)" [size]="17" />
            </div>
            <div class="notif-body">
              <div class="notif-head">
                <strong>{{ n.title || 'Notification' }}</strong>
                <span class="muted small nowrap">{{ n.createdAt | date: 'dd/MM/yyyy · HH:mm' }}</span>
              </div>
              <p>{{ n.body }}</p>
              <div class="row" style="margin-top:0.5rem">
                <span class="badge neutral no-dot">{{ n.type || 'info' }}</span>
                @if (!n.read) {
                  <button class="btn ghost sm" (click)="markRead(n)">
                    <app-icon name="check" [size]="13" />
                    Marquer comme lu
                  </button>
                }
              </div>
            </div>
          </div>
        } @empty {
          <div class="card">
            <div class="empty">
              <div class="empty-icon"><app-icon name="bell" [size]="24" /></div>
              <strong>
                {{ unreadOnly() ? 'Aucune notification non lue' : 'Aucune notification' }}
              </strong>
              <p>
                Les mises à jour de vos signalements et réclamations apparaîtront ici.
              </p>
            </div>
          </div>
        }
      </div>
    }
  `,
})
export class NotificationsComponent implements OnInit {
  private readonly service = inject(NotificationService);
  readonly items = signal<AppNotification[]>([]);
  readonly allItems = signal<AppNotification[]>([]);
  readonly loading = signal(false);
  readonly unreadOnly = signal(false);

  readonly unreadCount = computed(() => this.allItems().filter((n) => !n.read).length);

  ngOnInit(): void {
    this.load();
    this.loadAll();
  }

  load(): void {
    this.loading.set(true);
    this.service.list(this.unreadOnly()).subscribe({
      next: (r) => {
        this.items.set(r.data ?? []);
        this.loading.set(false);
      },
      error: () => {
        this.items.set([]);
        this.loading.set(false);
      },
    });
  }

  private loadAll(): void {
    this.service.list(false).subscribe({
      next: (r) => this.allItems.set(r.data ?? []),
      error: () => this.allItems.set([]),
    });
  }

  setUnread(value: boolean): void {
    this.unreadOnly.set(value);
    this.load();
  }

  markRead(n: AppNotification): void {
    this.service.markRead(n.id).subscribe({
      next: () => {
        this.load();
        this.loadAll();
      },
    });
  }

  markAll(): void {
    this.service.markAllRead().subscribe({
      next: () => {
        this.load();
        this.loadAll();
      },
    });
  }

  iconFor(n: AppNotification): string {
    switch ((n.type ?? '').toLowerCase()) {
      case 'infraction':
        return 'reports';
      case 'support':
        return 'headset';
      case 'compte':
        return 'user';
      default:
        return 'bell';
    }
  }

  iconBg(n: AppNotification): string {
    switch ((n.type ?? '').toLowerCase()) {
      case 'infraction':
        return 'var(--primary-soft)';
      case 'support':
        return 'var(--violet-soft)';
      case 'compte':
        return 'var(--success-soft)';
      default:
        return 'var(--surface-3)';
    }
  }

  iconColor(n: AppNotification): string {
    switch ((n.type ?? '').toLowerCase()) {
      case 'infraction':
        return 'var(--primary)';
      case 'support':
        return 'var(--violet)';
      case 'compte':
        return 'var(--success)';
      default:
        return 'var(--muted)';
    }
  }
}
