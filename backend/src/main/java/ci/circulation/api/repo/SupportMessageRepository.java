package ci.circulation.api.repo;

import ci.circulation.api.domain.SupportMessage;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SupportMessageRepository extends JpaRepository<SupportMessage, String> {
    List<SupportMessage> findByReclamationIdOrderByCreatedAtAsc(String reclamationId);
}
