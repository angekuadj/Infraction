import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Infraction } from '../models/api.models';

interface ListResponse<T> {
  data: T[];
}

@Injectable({ providedIn: 'root' })
export class InfractionService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/api/infractions`;

  list(): Observable<ListResponse<Infraction>> {
    return this.http.get<ListResponse<Infraction>>(this.base);
  }

  forMyPlate(plaque: string): Observable<ListResponse<Infraction>> {
    return this.http.get<ListResponse<Infraction>>(`${this.base}/for-my-plate`, {
      params: new HttpParams().set('plaque', plaque),
    });
  }

  get(id: string): Observable<{ data: Infraction }> {
    return this.http.get<{ data: Infraction }>(`${this.base}/${id}`);
  }

  create(fields: Record<string, unknown>): Observable<{ data: Infraction }> {
    return this.http.post<{ data: Infraction }>(this.base, fields);
  }

  createWithFiles(
    fields: Record<string, string>,
    files: { video?: File; photo?: File; plate?: File },
  ): Observable<{ data: Infraction }> {
    const form = new FormData();
    Object.entries(fields).forEach(([k, v]) => {
      if (v != null) form.append(k, v);
    });
    if (files.video) form.append('video', files.video);
    if (files.photo) form.append('photo', files.photo);
    if (files.plate) form.append('plate', files.plate);
    return this.http.post<{ data: Infraction }>(this.base, form);
  }

  updateStatus(id: string, status: string, comment?: string): Observable<{ data: Infraction }> {
    return this.http.patch<{ data: Infraction }>(`${this.base}/${id}/status`, {
      status,
      statut: status,
      comment,
    });
  }

  updatePlate(id: string, plaque: string): Observable<{ data: Infraction }> {
    return this.http.patch<{ data: Infraction }>(`${this.base}/${id}/plate`, {
      plaque,
      plaqueImmatriculation: plaque,
      numeroImmatriculation: plaque,
    });
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/${id}`);
  }

  lock(id: string): Observable<{ data: Infraction }> {
    return this.http.post<{ data: Infraction }>(`${this.base}/${id}/lock`, {});
  }

  unlock(id: string): Observable<{ data: Infraction }> {
    return this.http.post<{ data: Infraction }>(`${this.base}/${id}/unlock`, {});
  }
}
