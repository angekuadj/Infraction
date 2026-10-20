package ci.circulation.api.web;

import ci.circulation.api.domain.Notification;
import ci.circulation.api.service.NotificationService;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import ci.circulation.api.common.SecurityUtils;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notifications;

    public NotificationController(NotificationService notifications) {
        this.notifications = notifications;
    }

    @GetMapping
    public Map<String, Object> list(Authentication authentication,
                                    @RequestParam(value = "unreadOnly", defaultValue = "false") boolean unreadOnly) {
        var user = SecurityUtils.currentUser(authentication);
        List<Map<String, Object>> items = notifications.list(user, unreadOnly)
                .stream().map(notifications::toMap).collect(Collectors.toList());
        return Map.of("data", items, "notifications", items);
    }

    @PostMapping("/read-all")
    public Map<String, Object> readAll(Authentication authentication) {
        var user = SecurityUtils.currentUser(authentication);
        int updated = notifications.markAllRead(user);
        return Map.of("message", "Notifications marquées comme lues.", "updated", updated);
    }

    @PostMapping("/{id}/read")
    public Map<String, Object> read(Authentication authentication, @PathVariable String id) {
        var user = SecurityUtils.currentUser(authentication);
        Notification n = notifications.markRead(user, id);
        return Map.of("data", notifications.toMap(n), "message", "Notification lue.");
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> get(Authentication authentication, @PathVariable String id) {
        var user = SecurityUtils.currentUser(authentication);
        Notification n = notifications.markRead(user, id);
        return ResponseEntity.ok(Map.of("data", notifications.toMap(n)));
    }
}
