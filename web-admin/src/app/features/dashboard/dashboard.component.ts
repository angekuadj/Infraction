import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { InfractionService } from '../../core/services/infraction.service';
import { InfractionTypeService } from '../../core/services/infraction-type.service';
import { SupportService } from '../../core/services/support.service';
import { AuthService } from '../../core/services/auth.service';
import { Infraction, InfractionType, Reclamation } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';
import { canQualify, canSupport, canValidate, displayName, roleLabel } from '../../core/roles';
import {
  infractionStatus,
  mainMedia,
  plateOf,
  statusLabel,
  statusTone,
} from '../../core/infraction-workflow';

@Component({
  selector: 'app-dashboard',
  imports: [DatePipe, RouterLink, IconComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Vue d'ensemble</span>
        <h1>Bonjour, {{ firstName() }}</h1>
        <span class="page-sub">{{ greeting() }}</span>
      </div>
      <div class="btn-group">
        @if (qualify()) {
          <a class="btn secondary" routerLink="/signalements" [queryParams]="{ vue: 'quipux' }">
            <app-icon name="scan-plate" [size]="16" />
            File Quipux
          </a>
        }
        @if (validate()) {
          <a class="btn secondary" routerLink="/signalements" [queryParams]="{ vue: 'police' }">
            <app-icon name="shield" [size]="16" />
            Validation police
          </a>
        }
        <a class="btn" routerLink="/signalements" [queryParams]="{ new: '1' }">
          <app-icon name="plus" [size]="16" />
          Nouveau signalement
        </a>
      </div>
    </div>

    <div class="kpi-grid">
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Signalements reçus</span>
          <div class="kpi-icon"><app-icon name="reports" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ total() }}</div>
        <div class="kpi-foot">
          <span class="kpi-trend up">+{{ todayCount() }}</span>
          <span>aujourd'hui</span>
        </div>
      </div>

      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">À qualifier (Quipux)</span>
          <div class="kpi-icon amber"><app-icon name="scan-plate" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ counts().pending }}</div>
        <div class="kpi-foot">
          <app-icon name="clock" [size]="13" />
          <span>en attente de qualification</span>
        </div>
      </div>

      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">En attente police</span>
          <div class="kpi-icon violet"><app-icon name="shield" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ counts().constatee }}</div>
        <div class="kpi-foot">
          <span class="kpi-trend down">{{ refusals() }}</span>
          <span>refusés au total</span>
        </div>
      </div>

      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Signalements validés</span>
          <div class="kpi-icon green"><app-icon name="check-circle" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ counts().validee }}</div>
        <div class="kpi-foot">
          <app-icon name="check" [size]="13" />
          <span>{{ validationRate() }}% de taux de validation</span>
        </div>
      </div>
    </div>

    <div class="grid two section">
      <div class="card flush">
        <div class="card-head" style="padding:1.25rem 1.25rem 0.5rem">
          <div class="card-title">
            <strong>Derniers signalements</strong>
            <span>Les dossiers les plus récents de votre file.</span>
          </div>
          <a class="btn ghost sm" routerLink="/signalements">
            Tout voir
            <app-icon name="arrow-right" [size]="14" />
          </a>
        </div>
        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>Signalement</th>
                <th>Plaque</th>
                <th>Statut</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              @for (i of recent(); track i.id) {
                <tr class="clickable" (click)="open(i)">
                  <td>
                    <div class="cell-media">
                      @if (thumb(i); as src) {
                        <img class="thumb" [src]="src" alt="" />
                      } @else {
                        <div class="thumb-placeholder"><app-icon name="image" [size]="18" /></div>
                      }
                      <div>
                        <div class="cell-main">{{ typeName(i) }}</div>
                        <div class="cell-sub">{{ i.lieu || 'Lieu non précisé' }}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    @if (plateOf(i)) {
                      <span class="plate-tag">{{ plateOf(i) }}</span>
                    } @else {
                      <span class="muted small">Non lue</span>
                    }
                  </td>
                  <td>
                    <span class="badge" [class]="statusTone(i.status || i.statut)">
                      {{ statusLabel(i.status || i.statut) }}
                    </span>
                  </td>
                  <td class="muted small nowrap">{{ i.createdAt | date: 'dd MMM, HH:mm' }}</td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="4">
                    <div class="empty">
                      <div class="empty-icon"><app-icon name="reports" [size]="22" /></div>
                      <strong>Aucun signalement</strong>
                      <p>Les nouveaux signalements apparaîtront ici.</p>
                    </div>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>

      <div class="stack">
        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Répartition des dossiers</strong>
              <span>État du flux de traitement.</span>
            </div>
          </div>
          <div class="bar-list">
            @for (bar of bars(); track bar.key) {
              <div class="bar-row">
                <div class="bar-label">
                  <span>{{ bar.label }}</span>
                  <strong>{{ bar.value }}</strong>
                </div>
                <div class="bar-track">
                  <div class="bar-fill" [class]="bar.tone" [style.width.%]="bar.pct"></div>
                </div>
              </div>
            }
          </div>
        </div>

        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Actions rapides</strong>
              <span>Accès direct aux files de traitement.</span>
            </div>
          </div>
          <div class="quick-actions">
            @if (qualify()) {
              <a class="quick-action" routerLink="/signalements" [queryParams]="{ vue: 'quipux' }">
                <div class="qa-icon"><app-icon name="scan-plate" [size]="18" /></div>
                <div>
                  <strong>Qualifier</strong>
                  <span>File Quipux</span>
                </div>
              </a>
            }
            @if (validate()) {
              <a class="quick-action" routerLink="/signalements" [queryParams]="{ vue: 'police' }">
                <div class="qa-icon"><app-icon name="shield" [size]="18" /></div>
                <div>
                  <strong>Valider</strong>
                  <span>File police</span>
                </div>
              </a>
            }
            <a class="quick-action" routerLink="/reclamations">
              <div class="qa-icon"><app-icon name="headset" [size]="18" /></div>
              <div>
                <strong>Réclamations</strong>
                <span>{{ openTickets() }} ouverte(s)</span>
              </div>
            </a>
            <a class="quick-action" routerLink="/rapports">
              <div class="qa-icon"><app-icon name="chart" [size]="18" /></div>
              <div>
                <strong>Rapports</strong>
                <span>Statistiques détaillées</span>
              </div>
            </a>
          </div>
        </div>
      </div>
    </div>

    <div class="grid two">
      <div class="card">
        <div class="card-head">
          <div class="card-title">
            <strong>Activité de traitement</strong>
            <span>Progression du flux Quipux → Police.</span>
          </div>
          <span class="chip blue">{{ roleLabel(auth.role()) }}</span>
        </div>
        <div class="steps">
          @for (step of steps(); track step.label; let idx = $index) {
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
        <div class="timeline" style="margin-top:0.8rem">
          @for (event of activity(); track event.title) {
            <div class="tl-item">
              <div class="tl-dot" [class]="event.tone">
                <app-icon [name]="event.icon" [size]="13" />
              </div>
              <div class="tl-content">
                <strong>{{ event.title }}</strong>
                <p>{{ event.detail }}</p>
              </div>
            </div>
          } @empty {
            <p class="muted small">Aucune activité récente.</p>
          }
        </div>
      </div>

      <div class="card">
        <div class="card-head">
          <div class="card-title">
            <strong>Réclamations récentes</strong>
            <span>Suivi des demandes usagers.</span>
          </div>
          <a class="btn ghost sm" routerLink="/reclamations">Ouvrir</a>
        </div>
        <div class="list">
          @for (r of tickets(); track r.id) {
            <div class="notif" style="padding:0.7rem 0.8rem">
              <div class="notif-icon">
                <app-icon name="message" [size]="16" />
              </div>
              <div class="notif-body">
                <div class="row-between">
                  <strong style="font-size:0.84rem">{{ r.subject }}</strong>
                  <span class="badge" [class]="ticketTone(r)">
                    {{ ticketLabel(r) }}
                  </span>
                </div>
                <p>{{ r.clientName || r.userName || 'Usager' }}</p>
              </div>
            </div>
          } @empty {
            <p class="muted small">Aucune réclamation en cours.</p>
          }
        </div>
      </div>
    </div>
  `,
})
export class DashboardComponent implements OnInit {
  private readonly infractionService = inject(InfractionService);
  private readonly typeService = inject(InfractionTypeService);
  private readonly supportService = inject(SupportService);
  private readonly router = inject(Router);
  readonly auth = inject(AuthService);

  readonly infractions = signal<Infraction[]>([]);
  readonly types = signal<InfractionType[]>([]);
  readonly reclamations = signal<Reclamation[]>([]);

  readonly qualify = computed(() => canQualify(this.auth.role()));
  readonly validate = computed(() => canValidate(this.auth.role()));
  readonly roleLabel = roleLabel;

  readonly firstName = computed(() => {
    const user = this.auth.user();
    const name = user?.prenom || user?.fullName || displayName(user);
    return name.split(' ')[0] || 'à vous';
  });

  readonly greeting = computed(() => {
    const role = this.auth.role();
    if (canQualify(role)) {
      return 'Voici les dossiers à qualifier et l’état général du traitement.';
    }
    if (canValidate(role)) {
      return 'Consultez les signalements qualifiés en attente de votre décision.';
    }
    if (canSupport(role)) {
      return 'Suivez les réclamations et l’activité de votre équipe support.';
    }
    return 'Retrouvez vos signalements, notifications et réclamations.';
  });

  readonly total = computed(() => this.infractions().length);
  readonly counts = computed(() => {
    const result = { pending: 0, constatee: 0, validee: 0, refusee: 0 };
    for (const i of this.infractions()) result[infractionStatus(i)]++;
    return result;
  });
  readonly refusals = computed(() => this.counts().refusee);
  readonly todayCount = computed(() => {
    const today = new Date().toDateString();
    return this.infractions().filter(
      (i) => i.createdAt && new Date(i.createdAt).toDateString() === today,
    ).length;
  });
  readonly validationRate = computed(() => {
    const c = this.counts();
    const decided = c.validee + c.refusee;
    return decided === 0 ? 0 : Math.round((c.validee / decided) * 100);
  });

  readonly recent = computed(() => this.infractions().slice(0, 5));
  readonly tickets = computed(() => this.reclamations().slice(0, 4));
  readonly openTickets = computed(() => this.reclamations().filter((r) => !r.closed).length);

  readonly bars = computed(() => {
    const c = this.counts();
    const total = Math.max(1, this.total());
    return [
      { key: 'pending', label: 'À qualifier', value: c.pending, tone: 'amber', pct: (c.pending / total) * 100 },
      {
        key: 'constatee',
        label: 'En attente police',
        value: c.constatee,
        tone: '',
        pct: (c.constatee / total) * 100,
      },
      {
        key: 'validee',
        label: 'Validés',
        value: c.validee,
        tone: 'green',
        pct: (c.validee / total) * 100,
      },
      {
        key: 'refusee',
        label: 'Refusés',
        value: c.refusee,
        tone: 'red',
        pct: (c.refusee / total) * 100,
      },
    ];
  });

  readonly steps = computed(() => {
    const c = this.counts();
    return [
      { label: 'Réception', state: 'done' as const },
      { label: 'Qualification', state: c.pending > 0 ? ('current' as const) : ('done' as const) },
      {
        label: 'Validation police',
        state:
          c.constatee > 0
            ? ('current' as const)
            : c.validee > 0
              ? ('done' as const)
              : ('rejected' as const),
      },
      { label: 'Clôturé', state: c.validee > 0 ? ('done' as const) : ('current' as const) },
    ];
  });

  readonly activity = computed(() => {
    const items = [...this.infractions()]
      .sort((a, b) => (b.updatedAt ?? b.createdAt ?? '').localeCompare(a.updatedAt ?? a.createdAt ?? ''))
      .slice(0, 4)
      .map((i) => {
        const status = infractionStatus(i);
        return {
          title:
            status === 'pending'
              ? `Signalement ${plateOf(i) || 'sans plaque'} reçu`
              : status === 'constatee'
                ? `Infraction qualifiée par Quipux`
                : status === 'validee'
                  ? `Signalement validé par la police`
                  : `Signalement refusé`,
          detail: `${this.typeName(i)} · ${i.lieu || 'Lieu non précisé'}`,
          icon: status === 'pending' ? 'clock' : status === 'constatee' ? 'scan-plate' : status === 'validee' ? 'check' : 'x',
          tone: status === 'pending' ? 'current' : status === 'constatee' ? 'current' : status === 'validee' ? 'done' : 'rejected',
        };
      });
    return items;
  });

  ngOnInit(): void {
    this.infractionService.list().subscribe({
      next: (r) => this.infractions.set(r.data ?? []),
      error: () => this.infractions.set([]),
    });
    this.typeService.list().subscribe({
      next: (r) => this.types.set(r.data ?? []),
      error: () => this.types.set([]),
    });
    this.supportService.list().subscribe({
      next: (r) => this.reclamations.set(r.data ?? []),
      error: () => this.reclamations.set([]),
    });
  }

  plateOf = plateOf;
  statusLabel = statusLabel;
  statusTone = statusTone;

  typeName(i: Infraction): string {
    const id = i.typeId ?? i.inciviTypeId;
    const found = this.types().find((t) => t.id === id);
    return found?.nom ?? id ?? 'Infraction';
  }

  thumb(i: Infraction): string | null {
    const media = mainMedia(i);
    return media.type === 'image' ? media.url : null;
  }

  ticketLabel(r: Reclamation): string {
    if (r.closed) return 'Fermée';
    return (r.status ?? r.statut) === 'en_cours' ? 'En cours' : 'Ouverte';
  }

  ticketTone(r: Reclamation): string {
    if (r.closed) return 'fermee';
    return (r.status ?? r.statut) === 'en_cours' ? 'en_cours' : 'ouverte';
  }

  open(i: Infraction): void {
    this.router.navigate(['/signalements'], { queryParams: { id: i.id } });
  }
}
