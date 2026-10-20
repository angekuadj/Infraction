package ci.circulation.api.repo;

import ci.circulation.api.domain.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, String> {
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    Optional<User> findByEmailOrPhone(String email, String phone);
    Optional<User> findByPlaqueImmatriculation(String plaqueImmatriculation);
    List<User> findByPlaqueImmatriculationContainingIgnoreCase(String partial);
}
