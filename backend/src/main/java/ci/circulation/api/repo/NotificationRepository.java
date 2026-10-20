package ci.circulation.api.repo;

import ci.circulation.api.domain.Notification;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface NotificationRepository extends JpaRepository<Notification, String> {
    List<Notification> findByUserIdOrderByCreatedAtDesc(String userId);
    List<Notification> findByUserIdAndReadFlagFalseOrderByCreatedAtDesc(String userId);

    @Modifying
    @Query("update Notification n set n.readFlag = true, n.seen = true where n.userId = ?1")
    int markAllRead(String userId);
}
