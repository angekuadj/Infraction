package ci.circulation.api.repo;

import ci.circulation.api.domain.ReclamationArchived;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface ReclamationArchivedRepository extends JpaRepository<ReclamationArchived, String> {
    List<ReclamationArchived> findByArchivedAtAfterOrderByArchivedAtDesc(Instant date);
    List<ReclamationArchived> findByArchivedByOrderByArchivedAtDesc(String archivedBy);
    List<ReclamationArchived> findByClientIdOrderByArchivedAtDesc(String clientId);
    List<ReclamationArchived> findAllByOrderByArchivedAtDesc();
}
