import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { SupportService } from '../../core/services/support.service';
import { AuthService } from '../../core/services/auth.service';
import { Reclamation, SupportMessage } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';
import { canSupport, isStaff } from '../../core/roles';

type SupportTab = 'queue' | 'assigned' | 'mine' | 'all';

@Component({
  selector: 'app-support',
  imports: [FormsModule, DatePipe, IconComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Assistance</span>
        <h1>Réclamations</h1>
        <span class="page-sub">
          @if (support()) {
            Traitez les demandes usagers, répondez et clôturez les conversations.
          } @else {
            Suivez vos réclamations et échangez avec le service client.
          }
        </span>
      </div>
      <button class="btn" (click)="openForm()">
        <app-icon name="plus" [size]="16" />
        Nouvelle réclamation
      </button>
    </div>

    <div class="grid three section">
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Ouvertes</span>
          <div class="kpi-icon amber"><app-icon name="message" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ openCount() }}</div>
        <div class="kpi-foot"><span>nécessitent une première réponse</span></div>
      </div>
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">En cours</span>
          <div class="kpi-icon"><app-icon name="headset" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ inProgressCount() }}</div>
        <div class="kpi-foot"><span>conversations actives</span></div>
      </div>
      <div class="kpi">
        <div class="kpi-top">
          <span class="kpi-label">Fermées</span>
          <div class="kpi-icon green"><app-icon name="check-circle" [size]="18" /></div>
        </div>
        <div class="kpi-value">{{ closedCount() }}</div>
        <div class="kpi-foot"><span>réclamations clôturées</span></div>
      </div>
    </div>

    <div class="card flush section" style="padding:0 1.25rem">
      <div class="tabs">
        @if (support()) {
          <button class="tab" [class.active]="tab() === 'queue'" (click)="switchTab('queue')">
            File d'attente
            <span class="tab-count">{{ queueCount() }}</span>
          </button>
          <button class="tab" [class.active]="tab() === 'assigned'" (click)="switchTab('assigned')">
            Mes assignations
          </button>
          <button class="tab" [class.active]="tab() === 'all'" (click)="switchTab('all')">
            Toutes
            <span class="tab-count">{{ reclamations().length }}</span>
          </button>
        }
        <button class="tab" [class.active]="tab() === 'mine'" (click)="switchTab('mine')">
          {{ support() ? 'Mes réclamations' : 'Mes demandes' }}
        </button>
      </div>
    </div>

    <div class="support-grid">
      <div class="ticket-list">
        @if (loading()) {
          <div class="loading"><span class="spinner"></span> Chargement…</div>
        } @else {
          @for (r of reclamations(); track r.id) {
            <div
              class="ticket"
              [class.selected]="selected()?.id === r.id"
              (click)="select(r)"
            >
              <div class="ticket-head">
                <strong>{{ r.subject }}</strong>
                <span class="badge" [class]="ticketTone(r)">{{ ticketLabel(r) }}</span>
              </div>
              <p class="ticket-preview">{{ r.message }}</p>
              <div class="ticket-meta">
                <app-icon name="user" [size]="13" />
                <span>{{ r.clientName || r.userName || 'Usager' }}</span>
                <span>·</span>
                <span>{{ r.createdAt | date: 'dd/MM · HH:mm' }}</span>
                @if (r.agentName) {
                  <span>·</span>
                  <span>{{ r.agentName }}</span>
                }
              </div>
            </div>
          } @empty {
            <div class="empty">
              <div class="empty-icon"><app-icon name="headset" [size]="22" /></div>
              <strong>Aucune réclamation</strong>
              <p>Les demandes des usagers apparaîtront ici.</p>
            </div>
          }
        }
      </div>

      @if (selected(); as r) {
        <div class="card flush chat">
          <div class="chat-head">
            <div class="chat-subject">
              <div class="row" style="gap:0.45rem">
                <span class="badge" [class]="ticketTone(r)">{{ ticketLabel(r) }}</span>
                @if (r.assignedTo) {
                  <span class="chip">Assignée à {{ r.agentName || 'un agent' }}</span>
                }
              </div>
              <strong>{{ r.subject }}</strong>
              <span>
                {{ r.clientName || r.userName || 'Usager' }} ·
                {{ r.createdAt | date: 'dd MMMM yyyy à HH:mm' }}
              </span>
            </div>
            @if (support()) {
              <div class="row">
                <button
                  class="btn sm danger-soft"
                  (click)="close(r)"
                  [disabled]="r.closed || busy()"
                >
                  <app-icon name="lock" [size]="14" />
                  {{ r.closed ? 'Clôturée' : 'Clôturer' }}
                </button>
              </div>
            }
          </div>

          <div class="chat-scroll">
            <div class="msg">
              <div class="msg-bubble">
                <span class="who">{{ r.clientName || r.userName || 'Usager' }}</span>
                <p>{{ r.message }}</p>
                <span class="msg-time">{{ r.createdAt | date: 'dd/MM HH:mm' }}</span>
              </div>
            </div>

            @for (m of messages(); track m.id) {
              <div class="msg" [class.mine]="isMine(m)">
                <div class="msg-bubble">
                  <span class="who">{{ m.senderName || (m.fromAgent ? 'Service client' : 'Usager') }}</span>
                  <p>{{ m.body }}</p>
                  <span class="msg-time">{{ m.createdAt | date: 'dd/MM HH:mm' }}</span>
                </div>
              </div>
            } @empty {
              <p class="muted small" style="text-align:center">
                Aucun message pour le moment. Démarrez la conversation.
              </p>
            }
          </div>

          @if (r.closed) {
            <div class="chat-composer" style="justify-content:center">
              <span class="muted small">
                <app-icon name="lock" [size]="13" /> Cette réclamation est clôturée. Envoyer un
                message la réouvrira.
              </span>
            </div>
          } @else {
            <div class="chat-composer">
              <textarea
                [(ngModel)]="reply"
                (keydown.enter)="onEnter($event)"
                placeholder="Écrire une réponse…"
                rows="1"
              ></textarea>
              <button class="btn" (click)="send()" [disabled]="!reply.trim() || sending()">
                <app-icon name="send" [size]="15" />
                Envoyer
              </button>
            </div>
          }
        </div>
      } @else {
        <div class="card chat-placeholder">
          <div class="empty">
            <div class="empty-icon"><app-icon name="message" [size]="24" /></div>
            <strong>Sélectionnez une réclamation</strong>
            <p>
              Choisissez une conversation dans la liste pour consulter les messages et
              répondre à l'usager.
            </p>
          </div>
        </div>
      }
    </div>

    @if (showForm()) {
      <div class="modal-backdrop" (click)="onBackdrop($event)">
        <div class="modal" (click)="$event.stopPropagation()">
          <div class="modal-head">
            <div class="drawer-title">
              <span class="eyebrow">Support</span>
              <h2>Nouvelle réclamation</h2>
              <span class="muted small">Décrivez votre demande, le service client vous répondra.</span>
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
            <label>
              Sujet
              <input
                type="text"
                [(ngModel)]="newSubject"
                placeholder="Ex : Contestation d'un signalement"
              />
            </label>
            <label>
              Message
              <textarea
                [(ngModel)]="newMessage"
                rows="5"
                placeholder="Expliquez votre situation avec le plus de détails possible…"
              ></textarea>
            </label>
            <div class="alert info">
              <app-icon name="info" [size]="16" />
              <span>
                Votre réclamation sera traitée par le service client. Vous recevrez une
                notification à chaque réponse.
              </span>
            </div>
          </div>
          <div class="modal-foot">
            <button class="btn ghost" (click)="showForm.set(false)">Annuler</button>
            <button class="btn" (click)="create()" [disabled]="busy() || !newSubject || !newMessage">
              <app-icon name="send" [size]="15" />
              Envoyer
            </button>
          </div>
        </div>
      </div>
    }
  `,
})
export class SupportComponent implements OnInit {
  private readonly service = inject(SupportService);
  private readonly auth = inject(AuthService);

  readonly tab = signal<SupportTab>('mine');
  readonly reclamations = signal<Reclamation[]>([]);
  readonly allReclamations = signal<Reclamation[]>([]);
  readonly messages = signal<SupportMessage[]>([]);
  readonly selected = signal<Reclamation | null>(null);
  readonly loading = signal(false);
  readonly busy = signal(false);
  readonly sending = signal(false);
  readonly showForm = signal(false);
  readonly formError = signal<string | null>(null);
  readonly support = computed(() => canSupport(this.auth.role()));

  newSubject = '';
  newMessage = '';
  reply = '';

  readonly openCount = computed(
    () => this.allReclamations().filter((r) => !r.closed && this.ticketKey(r) === 'ouverte').length,
  );
  readonly inProgressCount = computed(
    () => this.allReclamations().filter((r) => !r.closed && this.ticketKey(r) === 'en_cours').length,
  );
  readonly closedCount = computed(
    () => this.allReclamations().filter((r) => r.closed).length,
  );
  readonly queueCount = computed(
    () => this.allReclamations().filter((r) => !r.closed).length,
  );

  ngOnInit(): void {
    if (this.support()) {
      this.tab.set('queue');
    }
    this.load();
    this.loadSummary();
  }

  switchTab(tab: SupportTab): void {
    this.tab.set(tab);
    this.selected.set(null);
    this.messages.set([]);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    const tab = this.tab();
    const obs =
      tab === 'queue'
        ? this.service.queue()
        : tab === 'assigned'
          ? this.service.assigned()
          : this.service.list();
    obs.subscribe({
      next: (r) => {
        this.reclamations.set(r.data ?? []);
        this.loading.set(false);
      },
      error: () => {
        this.reclamations.set([]);
        this.loading.set(false);
      },
    });
  }

  private loadSummary(): void {
    this.service.list().subscribe({
      next: (r) => this.allReclamations.set(r.data ?? []),
      error: () => this.allReclamations.set([]),
    });
  }

  select(r: Reclamation): void {
    this.selected.set(r);
    this.reply = '';
    this.service.messages(r.id).subscribe({
      next: (res) => this.messages.set(res.data ?? []),
      error: () => this.messages.set([]),
    });
  }

  openForm(): void {
    this.newSubject = '';
    this.newMessage = '';
    this.formError.set(null);
    this.showForm.set(true);
  }

  onBackdrop(event: Event): void {
    if (event.target === event.currentTarget) this.showForm.set(false);
  }

  create(): void {
    if (!this.newSubject.trim() || !this.newMessage.trim()) return;
    this.busy.set(true);
    this.formError.set(null);
    this.service.create(this.newSubject.trim(), this.newMessage.trim()).subscribe({
      next: () => {
        this.busy.set(false);
        this.showForm.set(false);
        this.load();
        this.loadSummary();
      },
      error: (e) => {
        this.busy.set(false);
        this.formError.set(e?.error?.message ?? "Impossible d'envoyer la réclamation.");
      },
    });
  }

  onEnter(event: Event): void {
    const key = event as KeyboardEvent;
    if (key.shiftKey) return;
    event.preventDefault();
    this.send();
  }

  send(): void {
    const r = this.selected();
    const body = this.reply.trim();
    if (!r || !body || this.sending()) return;
    this.sending.set(true);
    this.reply = '';
    this.service.sendMessage(r.id, body).subscribe({
      next: () => {
        this.sending.set(false);
        this.select(r);
        this.load();
        this.loadSummary();
      },
      error: () => {
        this.sending.set(false);
        this.reply = body;
      },
    });
  }

  close(r: Reclamation): void {
    this.busy.set(true);
    this.service.close(r.id).subscribe({
      next: () => {
        this.busy.set(false);
        const updated = { ...r, closed: true, status: 'fermee' };
        this.selected.set(updated);
        this.load();
        this.loadSummary();
      },
      error: () => this.busy.set(false),
    });
  }

  isMine(m: SupportMessage): boolean {
    return isStaff(this.auth.role()) ? m.fromAgent : !m.fromAgent;
  }

  ticketKey(r: Reclamation): string {
    if (r.closed) return 'fermee';
    return (r.status ?? r.statut) === 'en_cours' ? 'en_cours' : 'ouverte';
  }

  ticketLabel(r: Reclamation): string {
    if (r.closed) return 'Fermée';
    return this.ticketKey(r) === 'en_cours' ? 'En cours' : 'Ouverte';
  }

  ticketTone(r: Reclamation): string {
    if (r.closed) return 'fermee';
    return this.ticketKey(r) === 'en_cours' ? 'en_cours' : 'ouverte';
  }
}
