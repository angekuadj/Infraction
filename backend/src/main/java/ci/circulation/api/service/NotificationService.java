package ci.circulation.api.service;

import ci.circulation.api.common.ApiException;
import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.domain.Notification;
import ci.circulation.api.domain.User;
import ci.circulation.api.repo.NotificationRepository;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {

    private final NotificationRepository notifications;

    public NotificationService(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    public List<Notification> list(User user, boolean unreadOnly) {
        return unreadOnly
                ? notifications.findByUserIdAndReadFlagFalseOrderByCreatedAtDesc(user.getId())
                : notifications.findByUserIdOrderByCreatedAtDesc(user.getId());
    }

    @Transactional
    public int markAllRead(User user) {
        return notifications.markAllRead(user.getId());
    }

    @Transactional
    public Notification markRead(User user, String id) {
        Notification n = notifications.findById(id)
                .orElseThrow(() -> ApiException.notFound("Notification introuvable."));
        if (!user.getId().equals(n.getUserId())) {
            throw ApiException.forbidden("Accès refusé à cette notification.");
        }
        n.setReadFlag(true);
        n.setSeen(true);
        n.setSeenAt(Instant.now());
        return notifications.save(n);
    }

    @Transactional
    public Notification create(String userId, String title, String body, String type) {
        Notification n = new Notification();
        n.setId(UUID.randomUUID().toString());
        n.setUserId(userId);
        n.setTitle(title);
        n.setSubject(title);
        n.setBody(body);
        n.setMessage(body);
        n.setType(type);
        return notifications.save(n);
    }

    public Map<String, Object> toMap(Notification n) {
        return DtoMapper.notification(n);
    }
}
