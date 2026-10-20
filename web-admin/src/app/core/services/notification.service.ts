import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AppNotification } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/api/notifications`;

  list(unreadOnly = false): Observable<{ data: AppNotification[] }> {
    return this.http.get<{ data: AppNotification[] }>(this.base, {
      params: new HttpParams().set('unreadOnly', String(unreadOnly)),
    });
  }

  markAllRead(): Observable<unknown> {
    return this.http.post(`${this.base}/read-all`, {});
  }

  markRead(id: string): Observable<unknown> {
    return this.http.post(`${this.base}/${id}/read`, {});
  }
}
