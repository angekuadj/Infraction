import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { InfractionService } from '../../core/services/infraction.service';
import { InfractionTypeService } from '../../core/services/infraction-type.service';
import { Infraction, InfractionType } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';
import { infractionStatus } from '../../core/infraction-workflow';

type Period = '7' | '30' | 'all';

@Component({
  selector: 'app-reports',
  imports: [IconComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Analyse</span>
        <h1>Rapports & statistiques</h1>
        <span class="page-sub">
          Analysez l'activité, les délais et la répartition des signalements.
        </span>
      </div>
      <div class="segmented">
        <button [class.active]="period() === '7'" (click)="period.set('7')">7 jours</button>
        <button [class.active]="period() === '30'" (click)="period.set('30')">30 jours</button>
        <button [class.active]="period() === 'all'" (click)="period.set('all')">Tout</button>
      </div>
    </div>

    @if (loading()) {
      <div class="loading"><span class="spinner"></span> Calcul des statistiques…</div>
    } @else {
      <div class="kpi-grid">
        <div class="kpi">
          <div class="kpi-top">
            <span class="kpi-label">Signalements</span>
            <div class="kpi-icon"><app-icon name="reports" [size]="18" /></div>
          </div>
          <div class="kpi-value">{{ scoped().length }}</div>
          <div class="kpi-foot"><span>sur la période sélectionnée</span></div>
        </div>
        <div class="kpi">
          <div class="kpi-top">
            <span class="kpi-label">Taux de validation</span>
            <div class="kpi-icon green"><app-icon name="check-circle" [size]="18" /></div>
          </div>
          <div class="kpi-value">{{ validationRate() }}%</div>
          <div class="kpi-foot"><span>des dossiers décidés</span></div>
        </div>
        <div class="kpi">
          <div class="kpi-top">
            <span class="kpi-label">En attente de traitement</span>
            <div class="kpi-icon amber"><app-icon name="clock" [size]="18" /></div>
          </div>
          <div class="kpi-value">{{ pendingTotal() }}</div>
          <div class="kpi-foot"><span>Quipux + police</span></div>
        </div>
        <div class="kpi">
          <div class="kpi-top">
            <span class="kpi-label">Type le plus fréquent</span>
            <div class="kpi-icon violet"><app-icon name="chart" [size]="18" /></div>
          </div>
          <div class="kpi-value" style="font-size:1.05rem;line-height:1.3;margin-top:0.4rem">
            {{ topType().label }}
          </div>
          <div class="kpi-foot"><span>{{ topType().value }} signalement(s)</span></div>
        </div>
      </div>

      <div class="grid two section">
        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Répartition par statut</strong>
              <span>État actuel du flux de traitement.</span>
            </div>
          </div>
          <div class="donut-row">
            <div class="donut" [style.background]="donutStyle()">
              <div class="donut-center">
                <strong>{{ scoped().length }}</strong>
                <span>dossiers</span>
              </div>
            </div>
            <div class="donut-legend">
              @for (item of statusBars(); track item.label) {
                <div class="legend-item">
                  <span class="legend-dot" [style.background]="item.color"></span>
                  <span class="legend-label">{{ item.label }}</span>
                  <strong>{{ item.value }}</strong>
                </div>
              }
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Types d'infraction</strong>
              <span>Les catégories les plus signalées.</span>
            </div>
          </div>
          <div class="bar-list">
            @for (bar of typeBars(); track bar.label) {
              <div class="bar-row">
                <div class="bar-label">
                  <span>{{ bar.label }}</span>
                  <strong>{{ bar.value }}</strong>
                </div>
                <div class="bar-track">
                  <div class="bar-fill" [style.width.%]="bar.pct"></div>
                </div>
              </div>
            } @empty {
              <p class="muted small">Aucune donnée sur cette période.</p>
            }
          </div>
        </div>
      </div>

      <div class="card section">
        <div class="card-head">
          <div class="card-title">
            <strong>Volume de signalements</strong>
            <span>Nombre de dossiers reçus par jour.</span>
          </div>
          <span class="chip">{{ periodLabel() }}</span>
        </div>
        <div class="chart">
          @for (col of volume(); track col.label) {
            <div class="chart-col">
              <div class="chart-track">
                <div class="chart-bar" [style.height.%]="col.pct" [title]="col.value + ' signalement(s)'">
                  @if (col.value > 0) {
                    <span class="chart-value">{{ col.value }}</span>
                  }
                </div>
              </div>
              <span class="chart-label">{{ col.label }}</span>
            </div>
          }
        </div>
      </div>

      <div class="grid two">
        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Par priorité</strong>
              <span>Niveau d'urgence des dossiers.</span>
            </div>
          </div>
          <div class="bar-list">
            @for (bar of priorityBars(); track bar.label) {
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
              <strong>Délai de qualification</strong>
              <span>Répartition des dossiers non encore qualifiés.</span>
            </div>
          </div>
          <div class="timeline">
            <div class="tl-item">
              <div class="tl-dot done"><app-icon name="clock" [size]="13" /></div>
              <div class="tl-content">
                <strong>Moins de 24 h</strong>
                <p>{{ ageBuckets().day }} signalement(s) récent(s).</p>
              </div>
            </div>
            <div class="tl-item">
              <div class="tl-dot current"><app-icon name="clock" [size]="13" /></div>
              <div class="tl-content">
                <strong>24 h à 48 h</strong>
                <p>{{ ageBuckets().twoDays }} dossier(s) à surveiller.</p>
              </div>
            </div>
            <div class="tl-item">
              <div class="tl-dot rejected"><app-icon name="alert" [size]="13" /></div>
              <div class="tl-content">
                <strong>Plus de 48 h</strong>
                <p>{{ ageBuckets().late }} dossier(s) en retard de traitement.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    }
  `,
})
export class ReportsComponent implements OnInit {
  private readonly service = inject(InfractionService);
  private readonly typeService = inject(InfractionTypeService);

  readonly infractions = signal<Infraction[]>([]);
  readonly types = signal<InfractionType[]>([]);
  readonly loading = signal(false);
  readonly period = signal<Period>('30');

  readonly scoped = computed(() => {
    const period = this.period();
    if (period === 'all') return this.infractions();
    const days = Number(period);
    const min = Date.now() - days * 24 * 60 * 60 * 1000;
    return this.infractions().filter((i) => {
      if (!i.createdAt) return true;
      const date = new Date(i.createdAt).getTime();
      return Number.isNaN(date) || date >= min;
    });
  });

  readonly counts = computed(() => {
    const result = { pending: 0, constatee: 0, validee: 0, refusee: 0 };
    for (const i of this.scoped()) result[infractionStatus(i)]++;
    return result;
  });

  readonly validationRate = computed(() => {
    const c = this.counts();
    const decided = c.validee + c.refusee;
    return decided === 0 ? 0 : Math.round((c.validee / decided) * 100);
  });

  readonly pendingTotal = computed(() => this.counts().pending + this.counts().constatee);

  readonly periodLabel = computed(() => {
    switch (this.period()) {
      case '7':
        return '7 derniers jours';
      case '30':
        return '30 derniers jours';
      case 'all':
        return 'Toute la période';
    }
  });

  readonly statusBars = computed(() => {
    const c = this.counts();
    return [
      { label: 'À qualifier', value: c.pending, color: '#d97706' },
      { label: 'En attente police', value: c.constatee, color: '#2563eb' },
      { label: 'Validés', value: c.validee, color: '#16a34a' },
      { label: 'Refusés', value: c.refusee, color: '#dc2626' },
    ];
  });

  readonly donutStyle = computed(() => {
    const total = Math.max(1, this.scoped().length);
    const c = this.counts();
    const a = (c.pending / total) * 100;
    const b = a + (c.constatee / total) * 100;
    const d = b + (c.validee / total) * 100;
    return `conic-gradient(#d97706 0 ${a}%, #2563eb ${a}% ${b}%, #16a34a ${b}% ${d}%, #dc2626 ${d}% 100%)`;
  });

  readonly typeBars = computed(() => {
    const counts = new Map<string, number>();
    for (const i of this.scoped()) {
      const name = this.typeName(i);
      counts.set(name, (counts.get(name) ?? 0) + 1);
    }
    const entries = [...counts.entries()].sort((a, b) => b[1] - a[1]).slice(0, 6);
    const max = Math.max(1, ...entries.map((e) => e[1]));
    return entries.map(([label, value]) => ({ label, value, pct: (value / max) * 100 }));
  });

  readonly topType = computed(() => {
    const first = this.typeBars()[0];
    return first ?? { label: '—', value: 0 };
  });

  readonly priorityBars = computed(() => {
    const counts = new Map<string, number>();
    for (const i of this.scoped()) {
      const priority = (i.priority ?? 'normale').toLowerCase();
      counts.set(priority, (counts.get(priority) ?? 0) + 1);
    }
    const total = Math.max(1, this.scoped().length);
    const tones: Record<string, string> = {
      urgente: 'red',
      haute: 'amber',
      normale: '',
      basse: 'green',
    };
    return ['urgente', 'haute', 'normale', 'basse'].map((key) => {
      const value = counts.get(key) ?? 0;
      return {
        label: key.charAt(0).toUpperCase() + key.slice(1),
        value,
        tone: tones[key] ?? '',
        pct: (value / total) * 100,
      };
    });
  });

  readonly volume = computed(() => {
    const days = this.period() === '7' ? 7 : 14;
    const buckets: { label: string; value: number }[] = [];
    for (let offset = days - 1; offset >= 0; offset--) {
      const date = new Date();
      date.setHours(0, 0, 0, 0);
      date.setDate(date.getDate() - offset);
      const label = date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
      const value = this.scoped().filter((i) => {
        if (!i.createdAt) return false;
        const created = new Date(i.createdAt);
        created.setHours(0, 0, 0, 0);
        return created.getTime() === date.getTime();
      }).length;
      buckets.push({ label, value });
    }
    const max = Math.max(1, ...buckets.map((b) => b.value));
    return buckets.map((b) => ({ ...b, pct: (b.value / max) * 100 }));
  });

  readonly ageBuckets = computed(() => {
    let day = 0;
    let twoDays = 0;
    let late = 0;
    const now = Date.now();
    for (const i of this.scoped()) {
      if (infractionStatus(i) !== 'pending') continue;
      const created = i.createdAt ? new Date(i.createdAt).getTime() : now;
      const hours = (now - created) / 3_600_000;
      if (hours < 24) day++;
      else if (hours < 48) twoDays++;
      else late++;
    }
    return { day, twoDays, late };
  });

  ngOnInit(): void {
    this.loading.set(true);
    this.service.list().subscribe({
      next: (r) => {
        this.infractions.set(r.data ?? []);
        this.loading.set(false);
      },
      error: () => {
        this.infractions.set([]);
        this.loading.set(false);
      },
    });
    this.typeService.list().subscribe({
      next: (r) => this.types.set(r.data ?? []),
      error: () => this.types.set([]),
    });
  }

  typeName(i: Infraction): string {
    const id = i.typeId ?? i.inciviTypeId;
    return this.types().find((t) => t.id === id)?.nom ?? id ?? 'Infraction';
  }
}
