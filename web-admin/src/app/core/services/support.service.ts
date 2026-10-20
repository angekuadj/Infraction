import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Reclamation, SupportMessage } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class SupportService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/api/support`;

  list(): Observable<{ data: Reclamation[] }> {
    return this.http.get<{ data: Reclamation[] }>(`${this.base}/reclamations`);
  }

  queue(): Observable<{ data: Reclamation[] }> {
    return this.http.get<{ data: Reclamation[] }>(`${this.base}/queue`);
  }

  assigned(): Observable<{ data: Reclamation[] }> {
    return this.http.get<{ data: Reclamation[] }>(`${this.base}/assigned`);
  }

  get(id: string): Observable<{ data: Reclamation }> {
    return this.http.get<{ data: Reclamation }>(`${this.base}/reclamations/${id}`);
  }

  create(subject: string, message: string): Observable<{ data: Reclamation }> {
    return this.http.post<{ data: Reclamation }>(`${this.base}/reclamations`, { subject, message });
  }

  messages(id: string): Observable<{ data: SupportMessage[] }> {
    return this.http.get<{ data: SupportMessage[] }>(`${this.base}/reclamations/${id}/messages`);
  }

  sendMessage(id: string, body: string): Observable<{ data: SupportMessage }> {
    return this.http.post<{ data: SupportMessage }>(`${this.base}/reclamations/${id}/messages`, { body });
  }

  close(id: string): Observable<{ data: Reclamation }> {
    return this.http.post<{ data: Reclamation }>(`${this.base}/reclamations/${id}/close`, {});
  }
}
