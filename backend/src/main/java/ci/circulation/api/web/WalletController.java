package ci.circulation.api.web;

import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.User;
import ci.circulation.api.domain.Wallet;
import ci.circulation.api.service.WalletService;
import java.util.Map;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/wallet")
public class WalletController {

    private final WalletService wallets;

    public WalletController(WalletService wallets) {
        this.wallets = wallets;
    }

    @GetMapping
    public Map<String, Object> get(Authentication authentication) {
        User user = SecurityUtils.currentUser(authentication);
        Wallet w = wallets.getOrCreate(user);
        return Map.of("data", DtoMapper.wallet(w));
    }
}
