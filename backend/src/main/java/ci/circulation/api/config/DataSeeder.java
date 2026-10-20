package ci.circulation.api.config;

import ci.circulation.api.domain.InfractionType;
import ci.circulation.api.domain.User;
import ci.circulation.api.domain.Wallet;
import ci.circulation.api.repo.InfractionTypeRepository;
import ci.circulation.api.repo.UserRepository;
import ci.circulation.api.repo.WalletRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataSeeder implements CommandLineRunner {

    private final InfractionTypeRepository types;
    private final UserRepository users;
    private final WalletRepository wallets;
    private final PasswordEncoder encoder;
    private final String adminEmail;
    private final String adminPassword;

    public DataSeeder(InfractionTypeRepository types,
                      UserRepository users,
                      WalletRepository wallets,
                      PasswordEncoder encoder,
                      @Value("${app.seed.admin-email}") String adminEmail,
                      @Value("${app.seed.admin-password}") String adminPassword) {
        this.types = types;
        this.users = users;
        this.wallets = wallets;
        this.encoder = encoder;
        this.adminEmail = adminEmail;
        this.adminPassword = adminPassword;
    }

    @Override
    public void run(String... args) {
        seedTypes();
        seedAdmin();
    }

    private void seedTypes() {
        if (types.count() > 0) return;
        List<String[]> defs = List.of(
                new String[]{"mauvais_stationnement", "Mauvais stationnement", "Stationnement devant une sortie, en double file, sur trottoir ou stationnement gênant.", "stationnement"},
                new String[]{"non_respect_code_route", "Non-respect du code de la route", "Feux rouges, sens interdits, circulation à contresens.", "circulation"},
                new String[]{"non_respect_arrets", "Non-respect des arrêts", "Arrêts et priorités non respectés.", "circulation"},
                new String[]{"conduite_dangereuse", "Conduite dangereuse", "Dépassement dangereux, excès de vitesse, conduite sans permis ou sans assurance.", "circulation"},
                new String[]{"non_respect_vie_commune", "Non-respect des règles de vie commune", "Tapage, désordre.", "vie_commune"},
                new String[]{"hausse_tarifs", "Hausse illégale des tarifs", "Refus de payer les impôts, fraude fiscale.", "economie"},
                new String[]{"activites_non_declarees", "Activités économiques non déclarées", "Activités économiques non déclarées.", "economie"},
                new String[]{"corruption", "Corruption et pots-de-vin", "Corruption et pots-de-vin.", "integrite"},
                new String[]{"pollution", "Pollution", "Jets de sachets plastiques, eaux usées, pollution environnementale.", "environnement"},
                new String[]{"documents", "Non-respect des procédures", "Non-respect des procédures administratives, corruption, falsification de documents.", "administration"});

        int ordre = 0;
        for (String[] d : defs) {
            InfractionType t = new InfractionType();
            t.setId(d[0]);
            t.setNom(d[1]);
            t.setDescription(d[2]);
            t.setCategory(d[3]);
            t.setOrdre(ordre++);
            t.setActif(true);
            types.save(t);
        }
    }

    private void seedAdmin() {
        if (users.findByEmail(adminEmail).isPresent()) return;
        User admin = new User();
        admin.setId(UUID.randomUUID().toString());
        admin.setNom("Admin");
        admin.setPrenom("Circulation");
        admin.setEmail(adminEmail);
        admin.setPhone("+22500000000");
        admin.setPassword(encoder.encode(adminPassword));
        admin.setRole("admin");
        admin.setActive(true);
        users.save(admin);

        Wallet w = new Wallet();
        w.setId(UUID.randomUUID().toString());
        w.setUserId(admin.getId());
        wallets.save(w);
    }
}
