import { Component, inject, OnInit, signal } from '@angular/core';
import { CurrencyPipe, DatePipe, DecimalPipe } from '@angular/common';
import { WalletService } from '../../core/services/wallet.service';
import { Wallet } from '../../core/models/api.models';
import { IconComponent } from '../../shared/icon.component';

@Component({
  selector: 'app-wallet',
  imports: [DatePipe, CurrencyPipe, DecimalPipe, IconComponent],
  template: `
    <div class="page-head">
      <div class="page-title">
        <span class="eyebrow">Mon compte</span>
        <h1>Portefeuille</h1>
        <span class="page-sub">Consultez votre solde et l'historique de vos opérations.</span>
      </div>
    </div>

    @if (wallet(); as w) {
      <div class="grid two section">
        <div class="card balance">
          <div class="row-between">
            <span class="muted">Solde disponible</span>
            <app-icon name="wallet" [size]="22" />
          </div>
          <strong class="amount">{{ w.solde | currency: 'XOF' : 'symbol' : '1.0-0' }}</strong>
          <span class="muted small">Dernière mise à jour : {{ w.updatedAt | date: 'dd/MM/yyyy HH:mm' }}</span>
        </div>

        <div class="card">
          <div class="card-head">
            <div class="card-title">
              <strong>Résumé</strong>
              <span>Mouvements enregistrés sur votre compte.</span>
            </div>
          </div>
          <div class="profile-row">
            <span class="muted">Nombre d'opérations</span>
            <strong>{{ w.operations.length }}</strong>
          </div>
          <div class="profile-row">
            <span class="muted">Total crédité</span>
            <strong class="pos">{{ credited() | currency: 'XOF' : 'symbol' : '1.0-0' }}</strong>
          </div>
          <div class="profile-row">
            <span class="muted">Total débité</span>
            <strong class="neg">{{ debited() | currency: 'XOF' : 'symbol' : '1.0-0' }}</strong>
          </div>
        </div>
      </div>

      <div class="card flush">
        <div class="card-head" style="padding:1.25rem 1.25rem 0.75rem">
          <div class="card-title">
            <strong>Historique des opérations</strong>
            <span>Toutes les transactions de votre portefeuille.</span>
          </div>
        </div>
        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Type</th>
                <th>Description</th>
                <th style="text-align:right">Montant</th>
              </tr>
            </thead>
            <tbody>
              @for (op of w.operations; track op.id) {
                <tr>
                  <td class="muted small nowrap">{{ op.date | date: 'dd/MM/yyyy · HH:mm' }}</td>
                  <td><span class="badge neutral no-dot">{{ op.type || 'Opération' }}</span></td>
                  <td>{{ op.description || op.label || '—' }}</td>
                  <td
                    style="text-align:right;font-weight:600"
                    [class.pos]="op.amount > 0"
                    [class.neg]="op.amount < 0"
                  >
                    {{ op.amount > 0 ? '+' : '' }}{{ op.amount | number: '1.0-0' }}
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="4">
                    <div class="empty">
                      <div class="empty-icon"><app-icon name="wallet" [size]="22" /></div>
                      <strong>Aucune opération</strong>
                      <p>Les mouvements de votre portefeuille apparaîtront ici.</p>
                    </div>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>
    } @else {
      <div class="loading"><span class="spinner"></span> Chargement du portefeuille…</div>
    }
  `,
})
export class WalletComponent implements OnInit {
  private readonly service = inject(WalletService);
  readonly wallet = signal<Wallet | null>(null);

  ngOnInit(): void {
    this.service.get().subscribe({
      next: (r) => this.wallet.set(r.data),
      error: () => this.wallet.set(null),
    });
  }

  credited(): number {
    return (this.wallet()?.operations ?? [])
      .filter((op) => op.amount > 0)
      .reduce((sum, op) => sum + op.amount, 0);
  }

  debited(): number {
    return Math.abs(
      (this.wallet()?.operations ?? [])
        .filter((op) => op.amount < 0)
        .reduce((sum, op) => sum + op.amount, 0),
    );
  }
}
