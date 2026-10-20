package ci.circulation.api.repo;

import ci.circulation.api.domain.InfractionArchived;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface InfractionArchivedRepository extends JpaRepository<InfractionArchived, String> {
    List<InfractionArchived> findByArchivedAtAfterOrderByArchivedAtDesc(Instant date);
    List<InfractionArchived> findByArchivedByOrderByArchivedAtDesc(String archivedBy);
    List<InfractionArchived> findByPlaqueImmatriculationOrderByArchivedAtDesc(String plaque);
    List<InfractionArchived> findAllByOrderByArchivedAtDesc();
}
