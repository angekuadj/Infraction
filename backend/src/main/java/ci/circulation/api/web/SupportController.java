package ci.circulation.api.web;

import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.Reclamation;
import ci.circulation.api.domain.User;
import ci.circulation.api.service.SupportService;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/support")
public class SupportController {

    private final SupportService support;

    public SupportController(SupportService support) {
        this.support = support;
    }

    @GetMapping
    public Map<String, Object> list(Authentication authentication) {
        User user = SecurityUtils.currentUser(authentication);
        return asList(support.list(user));
    }

    @GetMapping("/queue")
    public Map<String, Object> queue() {
        return asList(support.queue());
    }

    @GetMapping("/assigned")
    public Map<String, Object> assigned(Authentication authentication) {
        User user = SecurityUtils.currentUser(authentication);
        return asList(support.assigned(user));
    }

    @GetMapping("/reclamations")
    public Map<String, Object> reclamations(Authentication authentication) {
        User user = SecurityUtils.currentUser(authentication);
        return asList(support.list(user));
    }

    @PostMapping("/reclamations")
    public Map<String, Object> create(Authentication authentication,
                                      @RequestBody Map<String, Object> body) {
        User user = SecurityUtils.currentUser(authentication);
        String subject = firstNonBlank(str(body.get("subject")), str(body.get("title")));
        String message = firstNonBlank(str(body.get("message")), str(body.get("body")));
        Reclamation r = support.create(user, subject, message);
        return Map.of("data", DtoMapper.reclamation(r));
    }

    @GetMapping("/reclamations/{id}")
    public Map<String, Object> get(Authentication authentication, @PathVariable String id) {
        User user = SecurityUtils.currentUser(authentication);
        Reclamation r = support.get(user, id);
        return Map.of("data", DtoMapper.reclamation(r));
    }

    @PostMapping("/reclamations/{id}/messages")
    public Map<String, Object> sendMessage(Authentication authentication,
                                           @PathVariable String id,
                                           @RequestBody Map<String, Object> body) {
        User user = SecurityUtils.currentUser(authentication);
        String message = firstNonBlank(str(body.get("body")), str(body.get("message")), str(body.get("content")));
        var saved = support.send(user, id, message);
        return Map.of("data", DtoMapper.supportMessage(saved));
    }

    @GetMapping("/reclamations/{id}/messages")
    public Map<String, Object> messages(Authentication authentication, @PathVariable String id) {
        User user = SecurityUtils.currentUser(authentication);
        List<Map<String, Object>> items = support.listMessages(user, id)
                .stream().map(DtoMapper::supportMessage).collect(Collectors.toList());
        return Map.of("data", items, "messages", items);
    }

    @PostMapping("/reclamations/{id}/close")
    public Map<String, Object> close(Authentication authentication, @PathVariable String id) {
        User user = SecurityUtils.currentUser(authentication);
        Reclamation r = support.close(user, id);
        return Map.of("data", DtoMapper.reclamation(r), "message", "Réclamation clôturée.");
    }

    private Map<String, Object> asList(List<Reclamation> list) {
        List<Map<String, Object>> items = list.stream()
                .map(DtoMapper::reclamation).collect(Collectors.toList());
        return Map.of("data", items, "reclamations", items);
    }

    private static String str(Object v) { return v == null ? null : v.toString(); }

    private static String firstNonBlank(String... values) {
        for (String v : values) {
            if (v != null && !v.isBlank()) return v;
        }
        return null;
    }
}
