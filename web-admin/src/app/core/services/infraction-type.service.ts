import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { InfractionType } from '../models/api.models';

@Injectable({ providedIn: 'root' })
export class InfractionTypeService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiBaseUrl}/api/infraction-types`;

  list(): Observable<{ data: InfractionType[] }> {
    return this.http.get<{ data: InfractionType[] }>(this.base);
  }
}
