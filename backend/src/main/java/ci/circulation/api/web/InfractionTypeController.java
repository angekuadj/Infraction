package ci.circulation.api.web;

import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.repo.InfractionTypeRepository;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/infraction-types")
public class InfractionTypeController {

    private final InfractionTypeRepository types;

    public InfractionTypeController(InfractionTypeRepository types) {
        this.types = types;
    }

    @GetMapping
    public Map<String, Object> list() {
        List<Map<String, Object>> items = types.findByActifTrueOrderByOrdreAsc()
                .stream().map(DtoMapper::infractionType).toList();
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("data", items);
        body.put("types", items);
        return body;
    }
}
