import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Wallet } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class WalletService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/api/wallet`;

  get(): Observable<{ data: Wallet }> {
    return this.http.get<{ data: Wallet }>(this.base);
  }
}
