package ci.circulation.api.common;

import ci.circulation.api.domain.*;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class DtoMapper {

    private DtoMapper() {}

    public static Map<String, Object> user(User u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("userId", u.getId());
        m.put("nom", u.getNom());
        m.put("prenom", u.getPrenom());
        m.put("fullName", displayName(u));
        m.put("email", u.getEmail());
        m.put("phone", u.getPhone());
        m.put("telephone", u.getPhone());
        m.put("role", u.getRole());
        m.put("plaqueImmatriculation", u.getPlaqueImmatriculation());
        m.put("numeroImmatriculation", u.getNumeroImmatriculation());
        m.put("matricule", u.getMatricule());
        m.put("agentPolice", u.getAgentPolice());
        m.put("cni", u.getCni());
        m.put("cniPhotoPath", u.getCniPhotoPath());
        m.put("cniPhotoUrl", u.getCniPhotoPath());
        m.put("isActive", u.isActive());
        m.put("active", u.isActive());
        m.put("enPanne", u.isEnPanne());
        m.put("createdAt", iso(u.getCreatedAt()));
        m.put("updatedAt", iso(u.getUpdatedAt()));
        return m;
    }

    public static Map<String, Object> userSummary(User u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("nom", u.getNom());
        m.put("prenom", u.getPrenom());
        m.put("fullName", displayName(u));
        m.put("phone", u.getPhone());
        m.put("role", u.getRole());
        m.put("plaqueImmatriculation", u.getPlaqueImmatriculation());
        return m;
    }

    public static String displayName(User u) {
        StringBuilder sb = new StringBuilder();
        if (u.getPrenom() != null && !u.getPrenom().isBlank()) sb.append(u.getPrenom()).append(' ');
        if (u.getNom() != null && !u.getNom().isBlank()) sb.append(u.getNom());
        if (sb.isEmpty()) {
            if (u.getEmail() != null) return u.getEmail();
            if (u.getPhone() != null) return u.getPhone();
            return "Utilisateur";
        }
        return sb.toString().trim();
    }

    public static Map<String, Object> infractionType(InfractionType t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.getId());
        m.put("nom", t.getNom());
        m.put("name", t.getNom());
        m.put("title", t.getNom());
        m.put("description", t.getDescription());
        m.put("category", t.getCategory());
        m.put("categorie", t.getCategory());
        m.put("ordre", t.getOrdre());
        m.put("order", t.getOrdre());
        m.put("actif", t.isActif());
        m.put("active", t.isActif());
        return m;
    }

    public static Map<String, Object> infraction(Infraction i) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", i.getId());
        m.put("serverId", i.getId());
        m.put("localId", i.getLocalId());
        m.put("typeId", i.getTypeId());
        m.put("inciviTypeId", i.getInciviTypeId());
        m.put("plaqueImmatriculation", i.getPlaqueImmatriculation());
        m.put("numeroImmatriculation", i.getNumeroImmatriculation());
        m.put("plaque", i.getPlaqueImmatriculation());
        m.put("description", i.getDescription());
        m.put("commentaire", i.getCommentaire());
        m.put("lieu", i.getLieu());
        m.put("adresse", i.getLieu());
        m.put("latitude", i.getLatitude());
        m.put("longitude", i.getLongitude());
        m.put("status", i.getStatus());
        m.put("statut", i.getStatus());
        m.put("priority", i.getPriority());
        m.put("videoPath", i.getVideoPath());
        m.put("photoPath", i.getPhotoPath());
        m.put("plateImagePath", i.getPlateImagePath());
        m.put("thumbnailPath", i.getThumbnailPath());
        m.put("videoUrl", i.getVideoUrl());
        m.put("imageUrl", i.getImageUrl());
        m.put("clientId", i.getClientId());
        m.put("clientName", i.getClientName());
        m.put("userId", i.getUserId());
        m.put("userName", i.getUserName());
        m.put("agentName", i.getAgentName());
        m.put("agentPolice", i.getAgentPolice());
        m.put("lockedBy", i.getLockedBy());
        m.put("lockedByUserId", i.getLockedByUserId());
        m.put("lockedAt", iso(i.getLockedAt()));
        m.put("createdAt", iso(i.getCreatedAt()));
        m.put("updatedAt", iso(i.getUpdatedAt()));
        m.put("reportedAt", iso(i.getReportedAt()));
        m.put("sentAt", iso(i.getSentAt()));
        m.put("retryCount", i.getRetryCount());
        m.put("isAnalyzed", i.getScore() != null);
        m.put("trimStart", i.getTrimStart());
        m.put("trimEnd", i.getTrimEnd());
        m.put("score", i.getScore());
        m.put("panneStart", i.getPanneStart());
        m.put("panneEnd", i.getPanneEnd());
        m.put("enPanne", i.isEnPanne());
        return m;
    }

    public static Map<String, Object> notification(Notification n) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", n.getId());
        m.put("notificationId", n.getId());
        m.put("title", n.getTitle());
        m.put("subject", n.getSubject() != null ? n.getSubject() : n.getTitle());
        m.put("body", n.getBody());
        m.put("message", n.getMessage() != null ? n.getMessage() : n.getBody());
        m.put("type", n.getType());
        m.put("read", n.isReadFlag());
        m.put("isRead", n.isReadFlag());
        m.put("seen", n.isSeen());
        m.put("createdAt", iso(n.getCreatedAt()));
        m.put("seenAt", iso(n.getSeenAt()));
        m.put("data", Map.of());
        return m;
    }

    public static Map<String, Object> reclamation(Reclamation r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("reclamationId", r.getId());
        m.put("subject", r.getSubject());
        m.put("title", r.getSubject());
        m.put("message", r.getMessage());
        m.put("body", r.getMessage());
        m.put("status", r.getStatus());
        m.put("statut", r.getStatus());
        m.put("clientId", r.getClientId());
        m.put("clientName", r.getClientName());
        m.put("userId", r.getUserId());
        m.put("userName", r.getUserName());
        m.put("assignedTo", r.getAssignedTo());
        m.put("agentName", r.getAgentName());
        m.put("closed", r.isClosed());
        m.put("createdAt", iso(r.getCreatedAt()));
        m.put("updatedAt", iso(r.getUpdatedAt()));
        m.put("closedAt", iso(r.getClosedAt()));
        return m;
    }

    public static Map<String, Object> supportMessage(SupportMessage s) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", s.getId());
        m.put("reclamationId", s.getReclamationId());
        m.put("sender", s.getSender());
        m.put("senderName", s.getSenderName());
        m.put("receiver", s.getReceiver());
        m.put("body", s.getBody());
        m.put("message", s.getBody());
        m.put("content", s.getBody());
        m.put("fromClient", s.isFromClient());
        m.put("fromAgent", s.isFromAgent());
        m.put("createdAt", iso(s.getCreatedAt()));
        m.put("sentAt", iso(s.getCreatedAt()));
        return m;
    }

    public static Map<String, Object> wallet(Wallet w) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", w.getId());
        m.put("userId", w.getUserId());
        m.put("solde", w.getSolde());
        m.put("amount", w.getSolde());
        m.put("balance", w.getSolde());
        List<Map<String, Object>> ops = w.getOperations().stream()
                .map(DtoMapper::walletOperation)
                .toList();
        m.put("operations", ops);
        m.put("history", ops);
        m.put("updatedAt", iso(w.getUpdatedAt()));
        return m;
    }

    public static Map<String, Object> walletOperation(WalletOperation o) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", o.getId());
        m.put("type", o.getType());
        m.put("amount", o.getAmount());
        m.put("description", o.getDescription());
        m.put("label", o.getLabel() != null ? o.getLabel() : o.getDescription());
        m.put("date", iso(o.getDate()));
        m.put("createdAt", iso(o.getCreatedAt()));
        return m;
    }

    public static String iso(Instant instant) {
        return instant == null ? null : instant.toString();
    }
}
