package ci.circulation.api.common;

import ci.circulation.api.domain.User;
import org.springframework.security.core.Authentication;

public final class SecurityUtils {

    private SecurityUtils() {}

    public static User currentUser(Authentication authentication) {
        if (authentication != null && authentication.getPrincipal() instanceof User user) {
            return user;
        }
        throw ApiException.unauthorized("Authentification requise.");
    }

    public static boolean isPrivileged(User user) {
        return switch (role(user)) {
            case "admin", "superviseur",
                 "agent_quipux", "agent_police", "police_terrain",
                 "service_client" -> true;
            default -> false;
        };
    }

    public static boolean isManager(User user) {
        String role = role(user);
        return role.equals("admin") || role.equals("superviseur");
    }

    /** Citoyen : utilisateur ou propriétaire (profils non-staff). */
    public static boolean isCitizen(User user) {
        return switch (role(user)) {
            case "user", "proprietaire", "usager", "client" -> true;
            default -> false;
        };
    }

    /** Agent équipu uniquement. */
    public static boolean isAgentQuipux(User user) {
        return "agent_quipux".equals(role(user));
    }

    /** Agent de police uniquement. */
    public static boolean isAgentPolice(User user) {
        return "agent_police".equals(role(user));
    }

    private static String role(User user) {
        return user.getRole() == null ? "" : user.getRole().toLowerCase().trim();
    }
}
