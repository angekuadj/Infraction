package ci.circulation.api.repo;

import ci.circulation.api.domain.Infraction;
import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InfractionRepository extends JpaRepository<Infraction, String> {
    List<Infraction> findByUserIdOrderByCreatedAtDesc(String userId);
    List<Infraction> findByPlaqueImmatriculationOrderByCreatedAtDesc(String plaque);
    List<Infraction> findByNumeroImmatriculationOrderByCreatedAtDesc(String numero);
    List<Infraction> findByPlaqueImmatriculationContainingIgnoreCaseOrderByCreatedAtDesc(String plaque);
    List<Infraction> findAllByOrderByCreatedAtDesc();
    List<Infraction> findByStatusOrderByCreatedAtDesc(String status);
    List<Infraction> findByStatusInOrderByCreatedAtDesc(List<String> statuses);
    List<Infraction> findByStatusInAndUpdatedAtBefore(List<String> statuses, Instant before);
}
