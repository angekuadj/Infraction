package ci.circulation.api.web;

import ci.circulation.api.common.ApiException;
import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.User;
import ci.circulation.api.repo.UserRepository;
import ci.circulation.api.service.AuthService;
import ci.circulation.api.service.FileStorageService;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private static final Set<String> ALLOWED_ROLES = Set.of(
            "user", "proprietaire",
            "agent_quipux", "agent_police", "police_terrain",
            "service_client", "superviseur", "admin");

    private final UserRepository users;
    private final AuthService authService;
    private final FileStorageService storage;

    public UserController(UserRepository users, AuthService authService, FileStorageService storage) {
        this.users = users;
        this.authService = authService;
        this.storage = storage;
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, Object> create(Authentication authentication,
                                      @RequestBody Map<String, Object> body) {
        User current = SecurityUtils.currentUser(authentication);
        requireManager(current);
        return authService.createUser(body, null);
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> createMultipart(
            Authentication authentication,
            @RequestParam(required = false) Map<String, String> fields,
            @RequestPart(name = "cniPhoto", required = false) MultipartFile cniPhoto,
            @RequestPart(name = "cni_photo", required = false) MultipartFile cniPhotoAlt) {
        User current = SecurityUtils.currentUser(authentication);
        requireManager(current);
        Map<String, Object> body = new LinkedHashMap<>();
        if (fields != null) body.putAll(fields);
        MultipartFile photo = cniPhoto != null ? cniPhoto : cniPhotoAlt;
        String path = null;
        if (photo != null && !photo.isEmpty()) {
            path = "/uploads/" + storage.store(photo);
        }
        return authService.createUser(body, path);
    }

    @GetMapping
    public Map<String, Object> list(Authentication authentication) {
        User current = SecurityUtils.currentUser(authentication);
        requireManager(current);
        List<Map<String, Object>> items = users.findAll().stream()
                .map(DtoMapper::user)
                .collect(Collectors.toList());
        items.sort((a, b) -> String.valueOf(b.get("createdAt"))
                .compareTo(String.valueOf(a.get("createdAt"))));
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("data", items);
        body.put("users", items);
        return body;
    }

    @PatchMapping("/{id}/active")
    public Map<String, Object> setActive(Authentication authentication,
                                         @PathVariable String id,
                                         @RequestBody Map<String, Object> body) {
        User current = SecurityUtils.currentUser(authentication);
        requireManager(current);
        User target = users.findById(id)
                .orElseThrow(() -> ApiException.notFound("Utilisateur introuvable."));
        boolean active = body.get("active") == null
                || Boolean.parseBoolean(String.valueOf(body.get("active")));
        if (!active && target.getId().equals(current.getId())) {
            throw ApiException.badRequest("Vous ne pouvez pas désactiver votre propre compte.");
        }
        target.setActive(active);
        users.save(target);
        return Map.of("data", DtoMapper.user(target));
    }

    @PatchMapping("/{id}/role")
    public Map<String, Object> setRole(Authentication authentication,
                                       @PathVariable String id,
                                       @RequestBody Map<String, Object> body) {
        User current = SecurityUtils.currentUser(authentication);
        requireManager(current);
        User target = users.findById(id)
                .orElseThrow(() -> ApiException.notFound("Utilisateur introuvable."));
        String role = body.get("role") == null ? null : String.valueOf(body.get("role"));
        role = role == null ? null : role.trim().toLowerCase();
        if (role == null || !ALLOWED_ROLES.contains(role)) {
            throw ApiException.badRequest("Profil invalide.");
        }
        target.setRole(role);
        users.save(target);
        return Map.of("data", DtoMapper.user(target));
    }

    @PatchMapping("/{id}/password")
    public Map<String, Object> changePassword(Authentication authentication,
                                              @PathVariable String id,
                                              @RequestBody Map<String, Object> body) {
        User current = SecurityUtils.currentUser(authentication);
        requireManager(current);
        String newPassword = body.get("password") == null ? null : String.valueOf(body.get("password"));
        return authService.changePassword(id, newPassword);
    }

    private static void requireManager(User user) {
        if (!SecurityUtils.isManager(user)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN",
                    "Accès réservé aux administrateurs et superviseurs.");
        }
    }
}
