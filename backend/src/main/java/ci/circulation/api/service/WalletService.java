package ci.circulation.api.service;

import ci.circulation.api.domain.User;
import ci.circulation.api.domain.Wallet;
import ci.circulation.api.repo.WalletRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class WalletService {

    private final WalletRepository wallets;

    public WalletService(WalletRepository wallets) {
        this.wallets = wallets;
    }

    @Transactional
    public Wallet getOrCreate(User user) {
        return wallets.findByUserId(user.getId()).orElseGet(() -> {
            Wallet w = new Wallet();
            w.setId(UUID.randomUUID().toString());
            w.setUserId(user.getId());
            return wallets.save(w);
        });
    }
}
