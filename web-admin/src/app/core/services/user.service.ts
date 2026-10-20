import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { CreateUserRequest, User } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/api/users`;

  list(): Observable<{ data: User[] }> {
    return this.http.get<{ data: User[] }>(this.base);
  }

  create(payload: CreateUserRequest, cniPhoto?: File | null): Observable<{ data: User }> {
    let body: CreateUserRequest | FormData = payload;
    if (cniPhoto) {
      const form = new FormData();
      Object.entries(payload).forEach(([k, v]) => {
        if (v !== null && v !== undefined) form.append(k, String(v));
      });
      form.append('cniPhoto', cniPhoto);
      body = form;
    }
    return this.http.post<{ data: User }>(this.base, body);
  }

  setActive(id: string, active: boolean): Observable<{ data: User }> {
    return this.http.patch<{ data: User }>(`${this.base}/${id}/active`, { active });
  }

  setRole(id: string, role: string): Observable<{ data: User }> {
    return this.http.patch<{ data: User }>(`${this.base}/${id}/role`, { role });
  }

  changePassword(id: string, password: string): Observable<{ data: User }> {
    return this.http.patch<{ data: User }>(`${this.base}/${id}/password`, { password });
  }
}
