package ci.circulation.api.service;

import ci.circulation.api.common.ApiException;
import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.config.JwtService;
import ci.circulation.api.domain.User;
import ci.circulation.api.domain.Wallet;
import ci.circulation.api.repo.UserRepository;
import ci.circulation.api.repo.WalletRepository;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository users;
    private final WalletRepository wallets;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final NotificationService notifications;

    public AuthService(UserRepository users, WalletRepository wallets,
                       PasswordEncoder encoder, JwtService jwt,
                       NotificationService notifications) {
        this.users = users;
        this.wallets = wallets;
        this.encoder = encoder;
        this.jwt = jwt;
        this.notifications = notifications;
    }

    /**
     * Inscription publique : crée un compte {@code user} ou {@code proprietaire}.
     * Les autres profils (agents, service client, superviseur, admin)
     * sont créés par un administrateur via {@link #createUser}.
     */
    @Transactional
    public Map<String, Object> register(Map<String, Object> body) {
        return register(body, null);
    }

    @Transactional
    public Map<String, Object> register(Map<String, Object> body, String cniPhotoPath) {
        String nom = str(body.get("nom"));
        String prenom = str(body.get("prenom"));
        String email = str(body.get("email"));
        String phone = firstNonBlank(
                str(body.get("phone")),
                str(body.get("telephone")),
                str(body.get("numero")));
        String password = str(body.get("password"));
        String cni = firstNonBlank(
                str(body.get("cni")),
                str(body.get("numeroCni")),
                str(body.get("cniNumero")));
        String plaque = firstNonBlank(
                str(body.get("plaqueImmatriculation")),
                str(body.get("numeroImmatriculation")),
                str(body.get("plaque")));
        String role = firstNonBlank(str(body.get("role")), "user");

        if (nom == null || nom.isBlank()) throw ApiException.badRequest("Le nom est obligatoire.");
        if (phone == null || phone.isBlank()) {
            throw ApiException.badRequest("Le numéro de téléphone est obligatoire.");
        }
        if (password == null || password.length() < 6) {
            throw ApiException.badRequest("Le mot de passe doit contenir au moins 6 caractères.");
        }

        // Déterminer le type d'inscription
        boolean isProprietaire = "proprietaire".equalsIgnoreCase(role) || plaque != null && !plaque.isBlank();

        if (isProprietaire) {
            // Proprietaire : plaque obligatoire, CNI facultatif
            if (plaque == null || plaque.isBlank()) {
                throw ApiException.badRequest("La plaque d'immatriculation est obligatoire pour un propriétaire.");
            }
            // CNI est facultatif pour proprietaire
        } else {
            // User : CNI obligatoire
            if ((cni == null || cni.isBlank()) && cniPhotoPath == null) {
                throw ApiException.badRequest("Le numéro de CNI ou la photo de CNI est obligatoire.");
            }
        }

        if (email != null && !email.isBlank() && users.findByEmail(email).isPresent()) {
            throw ApiException.conflict("Un compte existe déjà avec cet email.");
        }
        if (users.findByPhone(phone).isPresent()) {
            throw ApiException.conflict("Un compte existe déjà avec ce numéro de téléphone.");
        }

        User user = new User();
        user.setId(UUID.randomUUID().toString());
        user.setNom(nom);
        user.setPrenom(prenom);
        user.setEmail(email);
        user.setPhone(phone);
        user.setPassword(encoder.encode(password));
        user.setRole(isProprietaire ? "proprietaire" : "user");
        user.setCni(cni);
        user.setCniPhotoPath(cniPhotoPath);
        user.setPlaqueImmatriculation(plaque);
        user.setNumeroImmatriculation(plaque);
        user.setActive(true);
        users.save(user);
        createWallet(user.getId());

        notifications.create(user.getId(), "Bienvenue sur Circulation",
                "Votre compte a été créé avec succès.", "compte");
        return authResponse(user);
    }

    /**
     * Création d'un compte par un administrateur/superviseur (tous profils).
     */
    @Transactional
    public Map<String, Object> createUser(Map<String, Object> body, String cniPhotoPath) {
        String nom = str(body.get("nom"));
        String prenom = str(body.get("prenom"));
        String email = str(body.get("email"));
        String phone = firstNonBlank(
                str(body.get("phone")),
                str(body.get("telephone")),
                str(body.get("numero")));
        String password = str(body.get("password"));
        String role = normalizeRole(str(body.get("role")));
        String matricule = str(body.get("matricule"));
        String cni = firstNonBlank(
                str(body.get("cni")),
                str(body.get("numeroCni")),
                str(body.get("cniNumero")));
        String plaque = firstNonBlank(
                str(body.get("plaqueImmatriculation")),
                str(body.get("numeroImmatriculation")),
                str(body.get("plaque")));

        if (nom == null || nom.isBlank()) throw ApiException.badRequest("Le nom est obligatoire.");
        if (phone == null || phone.isBlank()) {
            throw ApiException.badRequest("Le numéro de téléphone est obligatoire.");
        }
        if (password == null || password.length() < 6) {
            throw ApiException.badRequest("Le mot de passe doit contenir au moins 6 caractères.");
        }
        if (("agent_police".equals(role) || "agent_quipux".equals(role) || "police_terrain".equals(role))
                && (matricule == null || matricule.isBlank())) {
            throw ApiException.badRequest("Le matricule est obligatoire pour un agent.");
        }
        if (email != null && !email.isBlank() && users.findByEmail(email).isPresent()) {
            throw ApiException.conflict("Un compte existe déjà avec cet email.");
        }
        if (users.findByPhone(phone).isPresent()) {
            throw ApiException.conflict("Un compte existe déjà avec ce numéro de téléphone.");
        }

        User user = new User();
        user.setId(UUID.randomUUID().toString());
        user.setNom(nom);
        user.setPrenom(prenom);
        user.setEmail(email);
        user.setPhone(phone);
        user.setPassword(encoder.encode(password));
        user.setRole(role);
        user.setMatricule(matricule);
        user.setAgentPolice(matricule);
        user.setCni(cni);
        user.setCniPhotoPath(cniPhotoPath);
        user.setPlaqueImmatriculation(plaque);
        user.setNumeroImmatriculation(plaque);
        user.setActive(true);
        users.save(user);
        createWallet(user.getId());

        notifications.create(user.getId(), "Compte créé",
                "Votre compte a été créé par un administrateur.", "compte");
        return Map.of("data", DtoMapper.user(user), "user", DtoMapper.user(user));
    }

    private void createWallet(String userId) {
        Wallet wallet = new Wallet();
        wallet.setId(UUID.randomUUID().toString());
        wallet.setUserId(userId);
        wallets.save(wallet);
    }

    public Map<String, Object> login(Map<String, Object> body) {
        String identifier = firstNonBlank(
                str(body.get("identifier")), str(body.get("email")),
                str(body.get("phone")), str(body.get("telephone")));
        String password = str(body.get("password"));
        if (identifier == null || identifier.isBlank() || password == null) {
            throw ApiException.badRequest("Identifiant et mot de passe requis.");
        }
        User user = users.findByEmail(identifier)
                .or(() -> users.findByPhone(identifier))
                .orElseThrow(() -> ApiException.unauthorized("Identifiants invalides."));
        if (!encoder.matches(password, user.getPassword())) {
            throw ApiException.unauthorized("Identifiants invalides.");
        }
        if (!user.isActive()) {
            throw ApiException.forbidden("Ce compte est désactivé.");
        }
        return authResponse(user);
    }

    public Map<String, Object> authResponse(User user) {
        String token = jwt.issue(user.getId(), user.getRole());
        Map<String, Object> userMap = DtoMapper.user(user);
        userMap.put("token", token);
        userMap.put("accessToken", token);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("token", token);
        data.put("user", userMap);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("token", token);
        response.put("accessToken", token);
        response.put("tokenType", "Bearer");
        response.put("user", userMap);
        response.put("data", data);
        return response;
    }

    @Transactional
    public Map<String, Object> updatePlaque(User user, Map<String, Object> body) {
        String plaque = firstNonBlank(
                str(body.get("plaque")),
                str(body.get("plaqueImmatriculation")),
                str(body.get("numeroImmatriculation")));
        if (plaque == null || plaque.isBlank()) {
            throw ApiException.badRequest("La plaque d'immatriculation est obligatoire.");
        }
        user.setPlaqueImmatriculation(plaque);
        user.setNumeroImmatriculation(plaque);
        users.save(user);
        return Map.of("message", "Plaque enregistrée.", "user", DtoMapper.user(user));
    }

    @Transactional
    public Map<String, Object> activateClient(User user, Map<String, Object> body) {
        String phone = str(body.get("phone"));
        if (phone != null && !phone.isBlank()) {
            users.findByPhone(phone).ifPresent(other -> {
                if (!other.getId().equals(user.getId())) {
                    throw ApiException.conflict("Ce numéro de téléphone est déjà utilisé.");
                }
            });
            user.setPhone(phone);
        }
        user.setRole("proprietaire");
        user.setActive(true);
        users.save(user);
        return Map.of("message", "Compte propriétaire activé.", "user", DtoMapper.user(user));
    }

    @Transactional
    public Map<String, Object> declarePanne(User user, Map<String, Object> body) {
        Instant start = parseInstant(str(body.get("start")));
        Instant end = parseInstant(str(body.get("end")));
        if (start == null) start = Instant.now();
        user.setEnPanne(true);
        user.setPanneStart(start);
        user.setPanneEnd(end);
        users.save(user);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("message", "Panne déclarée.");
        result.put("enPanne", true);
        result.put("panneStart", start.toString());
        result.put("panneEnd", end == null ? null : end.toString());
        return result;
    }

    @Transactional
    public Map<String, Object> changePassword(String userId, String newPassword) {
        if (newPassword == null || newPassword.length() < 6) {
            throw ApiException.badRequest("Le mot de passe doit contenir au moins 6 caractères.");
        }
        User user = users.findById(userId)
                .orElseThrow(() -> ApiException.notFound("Utilisateur introuvable."));
        user.setPassword(encoder.encode(newPassword));
        users.save(user);
        return Map.of("message", "Mot de passe modifié avec succès.", "data", DtoMapper.user(user));
    }

    @Transactional
    public Map<String, Object> changeOwnPassword(User user, String oldPassword, String newPassword) {
        if (oldPassword == null || oldPassword.isBlank()) {
            throw ApiException.badRequest("L'ancien mot de passe est requis.");
        }
        if (newPassword == null || newPassword.length() < 6) {
            throw ApiException.badRequest("Le nouveau mot de passe doit contenir au moins 6 caractères.");
        }
        if (!encoder.matches(oldPassword, user.getPassword())) {
            throw ApiException.unauthorized("L'ancien mot de passe est incorrect.");
        }
        user.setPassword(encoder.encode(newPassword));
        users.save(user);
        return Map.of("message", "Mot de passe modifié avec succès.", "data", DtoMapper.user(user));
    }

    private static Instant parseInstant(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Instant.parse(value);
        } catch (Exception e) {
            return null;
        }
    }

    private static String normalizeRole(String role) {
        if (role == null || role.isBlank()) return "user";
        return switch (role.toLowerCase().trim()) {
            case "user", "utilisateur" -> "user";
            case "usager" -> "usager";
            case "proprietaire", "propriétaire", "owner" -> "proprietaire";
            case "agent_quipux", "agentquipux" -> "agent_quipux";
            case "agent_police", "agentpolice" -> "agent_police";
            case "police_terrain", "policeterrain" -> "police_terrain";
            case "service_client", "serviceclient" -> "service_client";
            case "superviseur", "supervisor" -> "superviseur";
            case "admin", "administrateur" -> "admin";
            default -> throw new ApiException(org.springframework.http.HttpStatus.BAD_REQUEST,
                    "ROLE_NOT_ALLOWED", "Rôle non autorisé : " + role);
        };
    }

    private static String str(Object value) {
        return value == null ? null : value.toString();
    }

    private static String firstNonBlank(String... values) {
        for (String v : values) {
            if (v != null && !v.isBlank()) return v;
        }
        return null;
    }
}
