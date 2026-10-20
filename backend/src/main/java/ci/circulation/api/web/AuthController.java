package ci.circulation.api.web;

import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.User;
import ci.circulation.api.service.AuthService;
import ci.circulation.api.service.FileStorageService;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final FileStorageService storage;

    public AuthController(AuthService authService, FileStorageService storage) {
        this.authService = authService;
        this.storage = storage;
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody Map<String, Object> body) {
        return authService.login(body);
    }

    @PostMapping(value = "/register", consumes = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, Object> register(@RequestBody Map<String, Object> body) {
        return authService.register(body);
    }

    @PostMapping(value = "/register", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, Object> registerMultipart(
            @RequestParam(required = false) Map<String, String> fields,
            @RequestPart(name = "cniPhoto", required = false) MultipartFile cniPhoto,
            @RequestPart(name = "cni_photo", required = false) MultipartFile cniPhotoAlt) {
        Map<String, Object> body = new LinkedHashMap<>();
        if (fields != null) body.putAll(fields);
        MultipartFile photo = cniPhoto != null ? cniPhoto : cniPhotoAlt;
        String path = null;
        if (photo != null && !photo.isEmpty()) {
            path = "/uploads/" + storage.store(photo);
        }
        return authService.register(body, path);
    }

    @GetMapping("/me")
    public Map<String, Object> me(Authentication authentication) {
        User user = SecurityUtils.currentUser(authentication);
        return Map.of("data", Map.of("user", DtoMapper.user(user)));
    }

    @PostMapping("/plaque")
    public Map<String, Object> plaque(Authentication authentication,
                                      @RequestBody Map<String, Object> body) {
        return authService.updatePlaque(SecurityUtils.currentUser(authentication), body);
    }

    @PostMapping("/activate-client")
    public Map<String, Object> activateClient(Authentication authentication,
                                              @RequestBody(required = false) Map<String, Object> body) {
        return authService.activateClient(SecurityUtils.currentUser(authentication),
                body == null ? Map.of() : body);
    }

    @PostMapping("/panne")
    public Map<String, Object> panne(Authentication authentication,
                                     @RequestBody(required = false) Map<String, Object> body) {
        return authService.declarePanne(SecurityUtils.currentUser(authentication),
                body == null ? Map.of() : body);
    }

    @PostMapping("/change-password")
    public Map<String, Object> changePassword(Authentication authentication,
                                              @RequestBody Map<String, Object> body) {
        User user = SecurityUtils.currentUser(authentication);
        String oldPassword = body.get("oldPassword") == null ? null : String.valueOf(body.get("oldPassword"));
        String newPassword = body.get("newPassword") == null ? null : String.valueOf(body.get("newPassword"));
        return authService.changeOwnPassword(user, oldPassword, newPassword);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of("status", "UP"));
    }
}
