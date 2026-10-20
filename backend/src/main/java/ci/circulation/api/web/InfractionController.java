package ci.circulation.api.web;

import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.Infraction;
import ci.circulation.api.domain.User;
import ci.circulation.api.service.InfractionService;
import jakarta.servlet.http.HttpServletRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/infractions")
public class InfractionController {

    private final InfractionService infractions;

    public InfractionController(InfractionService infractions) {
        this.infractions = infractions;
    }

    @GetMapping
    public Map<String, Object> list(Authentication authentication) {
        User user = SecurityUtils.currentUser(authentication);
        List<Map<String, Object>> items = infractions.list(user)
                .stream().map(DtoMapper::infraction).collect(Collectors.toList());
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("data", items);
        body.put("infractions", items);
        return body;
    }

    @GetMapping("/for-my-plate")
    public Map<String, Object> forMyPlate(Authentication authentication,
                                         @RequestParam(value = "plaque", required = false) String plaque) {
        User user = SecurityUtils.currentUser(authentication);
        List<Map<String, Object>> items = infractions.forPlaque(user, plaque)
                .stream().map(DtoMapper::infraction).collect(Collectors.toList());
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("data", items);
        body.put("infractions", items);
        return body;
    }

    @GetMapping("/{id}")
    public Map<String, Object> get(Authentication authentication, @PathVariable String id) {
        User user = SecurityUtils.currentUser(authentication);
        Infraction i = infractions.get(user, id);
        return infractions.data(i);
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> createJson(Authentication authentication,
                                                          @RequestBody Map<String, String> body,
                                                          HttpServletRequest request) {
        User user = SecurityUtils.currentUser(authentication);
        String baseUrl = buildBaseUrl(request);
        Infraction saved = infractions.create(user, body, null, null, null, baseUrl);
        return ResponseEntity.ok(infractions.data(saved));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> createMultipart(Authentication authentication,
                                                              @RequestParam(required = false) Map<String, String> fields,
                                                              @RequestPart(name = "video", required = false) MultipartFile video,
                                                              @RequestPart(name = "photo", required = false) MultipartFile photo,
                                                              @RequestPart(name = "plate", required = false) MultipartFile plate,
                                                              @RequestPart(name = "image", required = false) MultipartFile image,
                                                              HttpServletRequest request) {
        User user = SecurityUtils.currentUser(authentication);
        String baseUrl = buildBaseUrl(request);
        Map<String, String> f = fields == null ? new LinkedHashMap<>() : fields;
        MultipartFile p = photo != null ? photo : image;
        Infraction saved = infractions.create(user, f, video, p, plate, baseUrl);
        return ResponseEntity.ok(infractions.data(saved));
    }

    @PatchMapping("/{id}/status")
    public Map<String, Object> updateStatus(Authentication authentication,
                                            @PathVariable String id,
                                            @RequestBody Map<String, Object> body) {
        User user = SecurityUtils.currentUser(authentication);
        String status = firstNonBlank(str(body.get("status")), str(body.get("statut")));
        Infraction updated = infractions.updateStatus(user, id, status);
        return infractions.data(updated);
    }

    @PatchMapping("/{id}/plate")
    public Map<String, Object> updatePlate(Authentication authentication,
                                           @PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        User user = SecurityUtils.currentUser(authentication);
        String plaque = firstNonBlank(
                str(body.get("plaque")),
                str(body.get("plaqueImmatriculation")),
                str(body.get("numeroImmatriculation")));
        Infraction updated = infractions.updatePlate(user, id, plaque);
        return infractions.data(updated);
    }

    @PostMapping("/{id}/lock")
    public Map<String, Object> lock(Authentication authentication,
                                    @PathVariable String id) {
        User user = SecurityUtils.currentUser(authentication);
        Infraction locked = infractions.lock(user, id);
        return infractions.data(locked);
    }

    @PostMapping("/{id}/unlock")
    public Map<String, Object> unlock(Authentication authentication,
                                      @PathVariable String id) {
        User user = SecurityUtils.currentUser(authentication);
        Infraction unlocked = infractions.unlock(user, id);
        return infractions.data(unlocked);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(Authentication authentication, @PathVariable String id) {
        User user = SecurityUtils.currentUser(authentication);
        infractions.delete(user, id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/plate-owner")
    public Map<String, Object> findPlateOwner(Authentication authentication,
                                               @RequestParam String plaque) {
        User user = SecurityUtils.currentUser(authentication);
        return infractions.findPlateOwner(user, plaque);
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

    private String buildBaseUrl(HttpServletRequest request) {
        String scheme = request.getScheme();
        String host = request.getHeader("Host");
        if (host == null) {
            host = request.getServerName() + ":" + request.getServerPort();
        }
        return scheme + "://" + host;
    }
}
