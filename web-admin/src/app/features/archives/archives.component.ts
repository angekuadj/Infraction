import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ArchiveService, InfractionArchived, ReclamationArchived } from '../../core/services/archive.service';
import { IconComponent } from '../../shared/icon.component';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-archives',
  imports: [DatePipe, FormsModule, IconComponent],
  template: `
    <div class="page">
      <header class="page-header">
        <div>
          <h1>Archives</h1>
          <p class="muted">Infractions et réclamations archivées</p>
        </div>
        <div class="row" style="gap:0.5rem">
          <button class="btn secondary" (click)="runArchive()" [disabled]="busy()">
            <app-icon name="refresh" [size]="14" />
            {{ busy() ? 'Archivage en cours...' : 'Exécuter l\'archivage' }}
          </button>
        </div>
      </header>

      @if (message()) {
        <div class="alert ok">
          <app-icon name="check-circle" [size]="16" />
          <span>{{ message() }}</span>
        </div>
      }

      <div class="tabs">
        <button
          class="tab"
          [class.active]="activeTab() === 'infractions'"
          (click)="activeTab.set('infractions')"
        >
          Infractions ({{ infractions().length }})
        </button>
        <button
          class="tab"
          [class.active]="activeTab() === 'reclamations'"
          (click)="activeTab.set('reclamations')"
        >
          Réclamations ({{ reclamations().length }})
        </button>
      </div>

      @if (activeTab() === 'infractions') {
        <div class="table-container">
          <table class="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Plaque</th>
                <th>Statut</th>
                <th>Lieu</th>
                <th>Client</th>
                <th>Agent Quipux</th>
                <th>Agent Police</th>
                <th>Archivé le</th>
                <th>Par</th>
                <th>Raison</th>
              </tr>
            </thead>
            <tbody>
              @for (item of infractions(); track item.id) {
                <tr>
                  <td class="small">{{ shortId(item.id) }}</td>
                  <td>
                    @if (item.plaqueImmatriculation) {
                      <span class="plate-tag">{{ item.plaqueImmatriculation }}</span>
                    } @else {
                      <span class="muted">—</span>
                    }
                  </td>
                  <td>
                    <span class="badge" [class]="statusTone(item.status)">
                      {{ statusLabel(item.status) }}
                    </span>
                  </td>
                  <td>{{ item.lieu || '—' }}</td>
                  <td>{{ item.clientName || '—' }}</td>
                  <td>{{ item.agentQuipuxName || '—' }}</td>
                  <td>{{ item.agentPoliceName || '—' }}</td>
                  <td class="small">{{ item.archivedAt | date: 'dd/MM/yyyy HH:mm' }}</td>
                  <td>{{ item.archivedBy || '—' }}</td>
                  <td class="small">{{ item.archivedReason || '—' }}</td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="10" class="empty-cell">
                    Aucune infraction archivée
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      }

      @if (activeTab() === 'reclamations') {
        <div class="table-container">
          <table class="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Sujet</th>
                <th>Statut</th>
                <th>Client</th>
                <th>Agent</th>
                <th>Clôturée le</th>
                <th>Archivée le</th>
                <th>Par</th>
                <th>Raison</th>
              </tr>
            </thead>
            <tbody>
              @for (item of reclamations(); track item.id) {
                <tr>
                  <td class="small">{{ shortId(item.id) }}</td>
                  <td>{{ item.subject || '—' }}</td>
                  <td>
                    <span class="badge" [class]="statusTone(item.status)">
                      {{ statusLabel(item.status) }}
                    </span>
                  </td>
                  <td>{{ item.clientName || '—' }}</td>
                  <td>{{ item.agentName || '—' }}</td>
                  <td class="small">{{ item.closedAt | date: 'dd/MM/yyyy HH:mm' }}</td>
                  <td class="small">{{ item.archivedAt | date: 'dd/MM/yyyy HH:mm' }}</td>
                  <td>{{ item.archivedBy || '—' }}</td>
                  <td class="small">{{ item.archivedReason || '—' }}</td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="9" class="empty-cell">
                    Aucune réclamation archivée
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      }
    </div>
  `,
  styles: `
    .page {
      padding: 2rem;
      max-width: 1400px;
      margin: 0 auto;
    }

    .page-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2rem;
    }

    .page-header h1 {
      margin: 0 0 0.25rem 0;
    }

    .page-header p {
      margin: 0;
    }

    .tabs {
      display: flex;
      gap: 0.5rem;
      margin-bottom: 1.5rem;
      border-bottom: 1px solid #e5e7eb;
      padding-bottom: 0.5rem;
    }

    .tab {
      padding: 0.5rem 1rem;
      border: none;
      background: none;
      cursor: pointer;
      border-radius: 0.5rem;
      font-weight: 500;
      color: #6b7280;
    }

    .tab:hover {
      background: #f3f4f6;
    }

    .tab.active {
      background: #eff6ff;
      color: #2563eb;
    }

    .table-container {
      overflow-x: auto;
      border: 1px solid #e5e7eb;
      border-radius: 0.5rem;
    }

    .table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.875rem;
    }

    .table th,
    .table td {
      padding: 0.75rem 1rem;
      text-align: left;
      border-bottom: 1px solid #e5e7eb;
    }

    .table th {
      background: #f9fafb;
      font-weight: 600;
      color: #374151;
    }

    .table tbody tr:hover {
      background: #f9fafb;
    }

    .empty-cell {
      text-align: center;
      padding: 2rem;
      color: #6b7280;
    }

    .small {
      font-size: 0.75rem;
      color: #6b7280;
    }

    .badge {
      display: inline-block;
      padding: 0.25rem 0.5rem;
      border-radius: 0.25rem;
      font-size: 0.75rem;
      font-weight: 500;
    }

    .badge.done {
      background: #dcfce7;
      color: #166534;
    }

    .badge.rejected {
      background: #fee2e2;
      color: #991b1b;
    }

    .badge.current {
      background: #fef3c7;
      color: #92400e;
    }

    .badge.pending {
      background: #e5e7eb;
      color: #374151;
    }

    .plate-tag {
      display: inline-block;
      padding: 0.25rem 0.5rem;
      background: #eff6ff;
      color: #1e40af;
      border-radius: 0.25rem;
      font-family: monospace;
      font-weight: 500;
    }

    .muted {
      color: #6b7280;
    }

    .row {
      display: flex;
      align-items: center;
    }

    .alert {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.75rem 1rem;
      border-radius: 0.5rem;
      margin-bottom: 1rem;
    }

    .alert.ok {
      background: #dcfce7;
      color: #166534;
    }
  `
})
export class ArchivesComponent {
  private readonly archiveService = inject(ArchiveService);
  private readonly auth = inject(AuthService);

  readonly activeTab = signal<'infractions' | 'reclamations'>('infractions');
  readonly infractions = signal<InfractionArchived[]>([]);
  readonly reclamations = signal<ReclamationArchived[]>([]);
  readonly busy = signal(false);
  readonly message = signal<string | null>(null);

  constructor() {
    this.loadInfractions();
    this.loadReclamations();
  }

  loadInfractions() {
    this.archiveService.listInfractions().subscribe({
      next: (response) => {
        this.infractions.set(response.data);
      },
      error: (error) => {
        console.error('Erreur lors du chargement des infractions archivées', error);
      }
    });
  }

  loadReclamations() {
    this.archiveService.listReclamations().subscribe({
      next: (response) => {
        this.reclamations.set(response.data);
      },
      error: (error) => {
        console.error('Erreur lors du chargement des réclamations archivées', error);
      }
    });
  }

  runArchive() {
    this.busy.set(true);
    this.message.set(null);

    this.archiveService.runArchive().subscribe({
      next: (response) => {
        this.message.set(response.message);
        this.busy.set(false);
        this.loadInfractions();
        this.loadReclamations();
      },
      error: (error) => {
        console.error('Erreur lors de l\'archivage', error);
        this.busy.set(false);
      }
    });
  }

  shortId(id: string): string {
    return id ? id.substring(0, 8) : '—';
  }

  statusLabel(status?: string): string {
    if (!status) return '—';
    const labels: Record<string, string> = {
      'validee': 'Validée',
      'validated': 'Validée',
      'refusee': 'Refusée',
      'rejected': 'Refusée',
      'constatee': 'Confirmée',
      'confirmed': 'Confirmée',
      'closed': 'Clôturée',
      'resolved': 'Résolue'
    };
    return labels[status.toLowerCase()] || status;
  }

  statusTone(status?: string): string {
    if (!status) return 'pending';
    const tones: Record<string, string> = {
      'validee': 'done',
      'validated': 'done',
      'refusee': 'rejected',
      'rejected': 'rejected',
      'constatee': 'done',
      'confirmed': 'done',
      'closed': 'done',
      'resolved': 'done'
    };
    return tones[status.toLowerCase()] || 'pending';
  }
}
