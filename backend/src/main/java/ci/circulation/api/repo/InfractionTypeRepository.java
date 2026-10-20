package ci.circulation.api.repo;

import ci.circulation.api.domain.InfractionType;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InfractionTypeRepository extends JpaRepository<InfractionType, String> {
    List<InfractionType> findByActifTrueOrderByOrdreAsc();
}
