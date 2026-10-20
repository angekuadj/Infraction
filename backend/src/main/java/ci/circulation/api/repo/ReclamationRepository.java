package ci.circulation.api.repo;

import ci.circulation.api.domain.Reclamation;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReclamationRepository extends JpaRepository<Reclamation, String> {
    List<Reclamation> findByUserIdOrderByCreatedAtDesc(String userId);
    List<Reclamation> findByClientIdOrderByCreatedAtDesc(String clientId);
    List<Reclamation> findByAssignedToOrderByCreatedAtDesc(String agentId);
    List<Reclamation> findByClosedFalseOrderByCreatedAtDesc();
    List<Reclamation> findAllByOrderByCreatedAtDesc();
}
