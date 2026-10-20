import { Injectable, inject, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthResponse, LoginRequest, RegisterRequest, User } from '../models/api.models';

const TOKEN_KEY = 'circulation_token';
const USER_KEY = 'circulation_user';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);

  private readonly _user = signal<User | null>(this.readUser());
  private readonly _token = signal<string | null>(localStorage.getItem(TOKEN_KEY));

  readonly user = this._user.asReadonly();
  readonly token = this._token.asReadonly();
  readonly isAuthenticated = computed(() => !!this._token());
  readonly role = computed(() => this._user()?.role ?? null);

  private readonly base = `${environment.apiBaseUrl}/api/auth`;

  login(payload: LoginRequest): Observable<AuthResponse> {
    return this.http
      .post<AuthResponse>(`${this.base}/login`, payload)
      .pipe(tap((res) => this.persist(res)));
  }

  register(payload: RegisterRequest, cniPhoto?: File | null): Observable<AuthResponse> {
    let body: RegisterRequest | FormData = payload;
    if (cniPhoto) {
      const form = new FormData();
      Object.entries(payload).forEach(([k, v]) => {
        if (v !== null && v !== undefined) form.append(k, String(v));
      });
      form.append('cniPhoto', cniPhoto);
      body = form;
    }
    return this.http
      .post<AuthResponse>(`${this.base}/register`, body)
      .pipe(tap((res) => this.persist(res)));
  }

  me(): Observable<{ data: { user: User } }> {
    return this.http
      .get<{ data: { user: User } }>(`${this.base}/me`)
      .pipe(
        tap((res) => {
          this._user.set(res.data.user);
          localStorage.setItem(USER_KEY, JSON.stringify(res.data.user));
        }),
      );
  }

  updatePlaque(plaque: string): Observable<unknown> {
    return this.http.post(`${this.base}/plaque`, { plaque, plaqueImmatriculation: plaque });
  }

  activateClient(phone?: string): Observable<unknown> {
    return this.http.post(`${this.base}/activate-client`, { phone });
  }

  declarePanne(start?: string, end?: string): Observable<unknown> {
    return this.http.post(`${this.base}/panne`, { start, end });
  }

  changePassword(oldPassword: string, newPassword: string): Observable<unknown> {
    return this.http.post(`${this.base}/change-password`, { oldPassword, newPassword });
  }

  logout(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    this._token.set(null);
    this._user.set(null);
    this.router.navigateByUrl('/login');
  }

  private persist(res: AuthResponse): void {
    const token = res.token ?? res.accessToken ?? res.data?.token ?? null;
    const user = res.user ?? res.data?.user ?? null;
    if (token) {
      localStorage.setItem(TOKEN_KEY, token);
      this._token.set(token);
    }
    if (user) {
      localStorage.setItem(USER_KEY, JSON.stringify(user));
      this._user.set(user);
    }
  }

  private readUser(): User | null {
    const raw = localStorage.getItem(USER_KEY);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as User;
    } catch {
      return null;
    }
  }
}
