package ci.circulation.api.service;

import ci.circulation.api.common.ApiException;
import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.Reclamation;
import ci.circulation.api.domain.SupportMessage;
import ci.circulation.api.domain.User;
import ci.circulation.api.repo.ReclamationRepository;
import ci.circulation.api.repo.SupportMessageRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SupportService {

    private final ReclamationRepository reclamations;
    private final SupportMessageRepository messages;
    private final NotificationService notifications;

    public SupportService(ReclamationRepository reclamations,
                          SupportMessageRepository messages,
                          NotificationService notifications) {
        this.reclamations = reclamations;
        this.messages = messages;
        this.notifications = notifications;
    }

    /** File d'attente des agents : réclamations ouvertes non assignées. */
    public List<Reclamation> queue() {
        return reclamations.findByClosedFalseOrderByCreatedAtDesc();
    }

    /** Réclamations assignées à l'agent courant. */
    public List<Reclamation> assigned(User user) {
        return reclamations.findByAssignedToOrderByCreatedAtDesc(user.getId());
    }

    /** Réclamations visibles par l'utilisateur courant. */
    public List<Reclamation> list(User user) {
        if (SecurityUtils.isPrivileged(user)) {
            return reclamations.findAllByOrderByCreatedAtDesc();
        }
        List<Reclamation> mine = reclamations.findByUserIdOrderByCreatedAtDesc(user.getId());
        if (mine.isEmpty()) {
            mine = reclamations.findByClientIdOrderByCreatedAtDesc(user.getId());
        }
        return mine;
    }

    @Transactional
    public Reclamation create(User user, String subject, String message) {
        if (subject == null || subject.isBlank()) {
            throw ApiException.badRequest("Le sujet de la réclamation est obligatoire.");
        }
        if (message == null || message.isBlank()) {
            throw ApiException.badRequest("Le message de la réclamation est obligatoire.");
        }
        Reclamation r = new Reclamation();
        r.setId(UUID.randomUUID().toString());
        r.setUserId(user.getId());
        r.setUserName(DtoMapper.displayName(user));
        r.setClientId(user.getId());
        r.setClientName(DtoMapper.displayName(user));
        r.setSubject(subject);
        r.setMessage(message);
        r.setStatus("ouverte");
        Reclamation saved = reclamations.save(r);

        notifications.create(user.getId(), "Réclamation enregistrée",
                "Votre réclamation \"" + subject + "\" a été transmise au support.", "support");
        return saved;
    }

    public Reclamation get(User user, String id) {
        Reclamation r = reclamations.findById(id)
                .orElseThrow(() -> ApiException.notFound("Réclamation introuvable."));
        if (!SecurityUtils.isPrivileged(user)
                && !user.getId().equals(r.getUserId())
                && !user.getId().equals(r.getClientId())
                && !user.getId().equals(r.getAssignedTo())) {
            throw ApiException.forbidden("Accès refusé à cette réclamation.");
        }
        return r;
    }

    public List<SupportMessage> listMessages(User user, String reclamationId) {
        get(user, reclamationId);
        return messages.findByReclamationIdOrderByCreatedAtAsc(reclamationId);
    }

    @Transactional
    public SupportMessage send(User user, String reclamationId, String body) {
        Reclamation r = get(user, reclamationId);
        if (body == null || body.isBlank()) {
            throw ApiException.badRequest("Le message est vide.");
        }
        boolean agent = SecurityUtils.isPrivileged(user);
        SupportMessage m = new SupportMessage();
        m.setId(UUID.randomUUID().toString());
        m.setReclamationId(reclamationId);
        m.setSender(user.getId());
        m.setSenderName(DtoMapper.displayName(user));
        m.setReceiver(agent ? r.getUserId() : r.getAssignedTo());
        m.setBody(body);
        m.setFromAgent(agent);
        m.setFromClient(!agent);
        SupportMessage saved = messages.save(m);

        if (r.isClosed()) {
            r.setClosed(false);
            r.setStatus("en_cours");
        } else if ("ouverte".equalsIgnoreCase(r.getStatus())) {
            r.setStatus("en_cours");
        }
        if (agent && (r.getAssignedTo() == null || r.getAssignedTo().isBlank())) {
            r.setAssignedTo(user.getId());
            r.setAgentName(DtoMapper.displayName(user));
        }
        reclamations.save(r);

        String notifyUser = agent ? r.getUserId() : r.getAssignedTo();
        if (notifyUser != null) {
            notifications.create(notifyUser, "Nouveau message support",
                    "Un nouveau message concernant \"" + r.getSubject() + "\".", "support");
        }
        return saved;
    }

    @Transactional
    public Reclamation close(User user, String id) {
        Reclamation r = get(user, id);
        r.setClosed(true);
        r.setStatus("fermee");
        r.setClosedAt(Instant.now());
        Reclamation saved = reclamations.save(r);
        if (r.getUserId() != null) {
            notifications.create(r.getUserId(), "Réclamation clôturée",
                    "Votre réclamation \"" + r.getSubject() + "\" a été clôturée.", "support");
        }
        return saved;
    }
}
