import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface InfractionArchived {
  id: string;
  plaqueImmatriculation?: string;
  status?: string;
  lieu?: string;
  clientName?: string;
  agentQuipuxName?: string;
  agentPoliceName?: string;
  createdAt?: string;
  updatedAt?: string;
  archivedAt?: string;
  archivedBy?: string;
  archivedReason?: string;
}

export interface ReclamationArchived {
  id: string;
  subject?: string;
  status?: string;
  clientName?: string;
  agentName?: string;
  closed?: boolean;
  closedAt?: string;
  createdAt?: string;
  updatedAt?: string;
  archivedAt?: string;
  archivedBy?: string;
  archivedReason?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ArchiveService {
  constructor(private http: HttpClient) {}

  private baseUrl = '/api/archive';

  listInfractions(): Observable<{ data: InfractionArchived[]; count: number }> {
    return this.http.get<{ data: InfractionArchived[]; count: number }>(
      `${this.baseUrl}/infractions`
    );
  }

  archiveInfraction(id: string, reason?: string): Observable<{ data: InfractionArchived; message: string }> {
    return this.http.post<{ data: InfractionArchived; message: string }>(
      `${this.baseUrl}/infractions/${id}`,
      reason ? { reason } : {}
    );
  }

  listReclamations(): Observable<{ data: ReclamationArchived[]; count: number }> {
    return this.http.get<{ data: ReclamationArchived[]; count: number }>(
      `${this.baseUrl}/reclamations`
    );
  }

  archiveReclamation(id: string, reason?: string): Observable<{ data: ReclamationArchived; message: string }> {
    return this.http.post<{ data: ReclamationArchived; message: string }>(
      `${this.baseUrl}/reclamations/${id}`,
      reason ? { reason } : {}
    );
  }

  runArchive(): Observable<{ infractionsArchived: number; reclamationsArchived: number; message: string }> {
    return this.http.post<{ infractionsArchived: number; reclamationsArchived: number; message: string }>(
      `${this.baseUrl}/run`,
      {}
    );
  }
}
