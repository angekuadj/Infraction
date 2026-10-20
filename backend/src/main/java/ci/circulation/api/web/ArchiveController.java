package ci.circulation.api.web;

import ci.circulation.api.common.ApiException;
import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.InfractionArchived;
import ci.circulation.api.domain.ReclamationArchived;
import ci.circulation.api.domain.User;
import ci.circulation.api.service.ArchiveService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/archive")
public class ArchiveController {

    private final ArchiveService archiveService;

    public ArchiveController(ArchiveService archiveService) {
        this.archiveService = archiveService;
    }

    private User getCurrentUser(HttpServletRequest request) {
        User user = (User) request.getAttribute("user");
        if (user == null) {
            throw ApiException.unauthorized("Utilisateur non authentifié");
        }
        return user;
    }

    /**
     * Lister toutes les infractions archivées
     */
    @GetMapping("/infractions")
    public ResponseEntity<Map<String, Object>> listArchivedInfractions(HttpServletRequest request) {
        User user = getCurrentUser(request);
        List<InfractionArchived> archived = archiveService.listArchivedInfractions(user);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("data", archived.stream().map(this::mapInfractionArchived).toList());
        response.put("count", archived.size());
        return ResponseEntity.ok(response);
    }

    /**
     * Archiver une infraction spécifique
     */
    @PostMapping("/infractions/{id}")
    public ResponseEntity<Map<String, Object>> archiveInfraction(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body,
            HttpServletRequest request) {
        User user = getCurrentUser(request);
        String reason = body != null ? body.get("reason") : "Archive manuelle";

        InfractionArchived archived = archiveService.archiveInfractionById(user, id, reason);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("data", mapInfractionArchived(archived));
        response.put("message", "Infraction archivée avec succès");
        return ResponseEntity.ok(response);
    }

    /**
     * Lister toutes les réclamations archivées
     */
    @GetMapping("/reclamations")
    public ResponseEntity<Map<String, Object>> listArchivedReclamations(HttpServletRequest request) {
        User user = getCurrentUser(request);
        List<ReclamationArchived> archived = archiveService.listArchivedReclamations(user);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("data", archived.stream().map(this::mapReclamationArchived).toList());
        response.put("count", archived.size());
        return ResponseEntity.ok(response);
    }

    /**
     * Archiver une réclamation spécifique
     */
    @PostMapping("/reclamations/{id}")
    public ResponseEntity<Map<String, Object>> archiveReclamation(
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body,
            HttpServletRequest request) {
        User user = getCurrentUser(request);
        String reason = body != null ? body.get("reason") : "Archive manuelle";

        ReclamationArchived archived = archiveService.archiveReclamationById(user, id, reason);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("data", mapReclamationArchived(archived));
        response.put("message", "Réclamation archivée avec succès");
        return ResponseEntity.ok(response);
    }

    /**
     * Déclencher manuellement l'archivage automatique
     */
    @PostMapping("/run")
    public ResponseEntity<Map<String, Object>> runArchive(HttpServletRequest request) {
        User user = getCurrentUser(request);

        if (!SecurityUtils.isPrivileged(user)) {
            throw ApiException.forbidden("Seuls les admins peuvent déclencher l'archivage.");
        }

        int infractionsArchived = archiveService.archiveOldInfractions();
        int reclamationsArchived = archiveService.archiveOldReclamations();

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("infractionsArchived", infractionsArchived);
        response.put("reclamationsArchived", reclamationsArchived);
        response.put("message", String.format("Archivage terminé: %d infractions, %d réclamations",
            infractionsArchived, reclamationsArchived));
        return ResponseEntity.ok(response);
    }

    private Map<String, Object> mapInfractionArchived(InfractionArchived i) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", i.getId());
        m.put("plaqueImmatriculation", i.getPlaqueImmatriculation());
        m.put("status", i.getStatus());
        m.put("lieu", i.getLieu());
        m.put("clientName", i.getClientName());
        m.put("agentQuipuxName", i.getAgentQuipuxName());
        m.put("agentPoliceName", i.getAgentPoliceName());
        m.put("createdAt", i.getCreatedAt());
        m.put("updatedAt", i.getUpdatedAt());
        m.put("archivedAt", i.getArchivedAt());
        m.put("archivedBy", i.getArchivedBy());
        m.put("archivedReason", i.getArchivedReason());
        return m;
    }

    private Map<String, Object> mapReclamationArchived(ReclamationArchived r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("subject", r.getSubject());
        m.put("status", r.getStatus());
        m.put("clientName", r.getClientName());
        m.put("agentName", r.getAgentName());
        m.put("closed", r.isClosed());
        m.put("closedAt", r.getClosedAt());
        m.put("createdAt", r.getCreatedAt());
        m.put("updatedAt", r.getUpdatedAt());
        m.put("archivedAt", r.getArchivedAt());
        m.put("archivedBy", r.getArchivedBy());
        m.put("archivedReason", r.getArchivedReason());
        return m;
    }
}
