package ci.circulation.api.service;

import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class SmsService {

    private static final Logger logger = LoggerFactory.getLogger(SmsService.class);

    @Value("${twilio.account.sid:}")
    private String accountSid;

    @Value("${twilio.auth.token:}")
    private String authToken;

    @Value("${twilio.phone.number:}")
    private String fromNumber;

    @Value("${twilio.enabled:false}")
    private boolean enabled;

    private boolean initialized = false;

    private void ensureInitialized() {
        if (!enabled) return;
        if (initialized) return;
        if (accountSid == null || accountSid.isBlank()) {
            logger.warn("Twilio non configuré: accountSid manquant");
            return;
        }
        if (authToken == null || authToken.isBlank()) {
            logger.warn("Twilio non configuré: authToken manquant");
            return;
        }
        if (fromNumber == null || fromNumber.isBlank()) {
            logger.warn("Twilio non configuré: fromNumber manquant");
            return;
        }
        try {
            Twilio.init(accountSid, authToken);
            initialized = true;
            logger.info("Twilio initialisé avec succès");
        } catch (Exception e) {
            logger.error("Erreur lors de l'initialisation de Twilio", e);
        }
    }

    public boolean sendSms(String toPhone, String message) {
        logger.info("=== Début envoi SMS ===");
        logger.info("Destinataire: {}", toPhone);
        logger.info("Message: {}", message);
        logger.info("Service Twilio activé: {}", enabled);

        if (!enabled) {
            logger.info("SMS désactivé (simulé vers: {})", toPhone);
            logger.info("=== Fin envoi SMS (simulé) ===");
            return true;
        }

        ensureInitialized();
        if (!initialized) {
            logger.warn("Impossible d'envoyer SMS: Twilio non initialisé");
            logger.warn("Account SID configuré: {}", accountSid != null && !accountSid.isBlank() ? "OUI" : "NON");
            logger.warn("Auth Token configuré: {}", authToken != null && !authToken.isBlank() ? "OUI" : "NON");
            logger.warn("From Number configuré: {}", fromNumber != null && !fromNumber.isBlank() ? fromNumber : "NON");
            logger.info("=== Fin envoi SMS (échec initialisation) ===");
            return false;
        }

        try {
            String normalizedTo = normalizePhoneNumber(toPhone);
            logger.info("Numéro normalisé: {}", normalizedTo);
            PhoneNumber to = new PhoneNumber(normalizedTo);
            PhoneNumber from = new PhoneNumber(fromNumber);

            logger.info("Tentative d'envoi SMS via Twilio...");
            Message msg = Message.creator(to, from, message).create();
            logger.info("✅ SMS envoyé avec succès");
            logger.info("SID du message: {}", msg.getSid());
            logger.info("Statut: {}", msg.getStatus());
            logger.info("=== Fin envoi SMS (succès) ===");
            return true;
        } catch (Exception e) {
            logger.error("❌ Erreur lors de l'envoi du SMS vers {}", toPhone);
            logger.error("Type d'erreur: {}", e.getClass().getSimpleName());
            logger.error("Message d'erreur: {}", e.getMessage());
            logger.info("=== Fin envoi SMS (échec) ===");
            return false;
        }
    }

    public boolean sendWhatsApp(String toPhone, String message) {
        logger.info("=== Début envoi WhatsApp ===");
        logger.info("Destinataire: {}", toPhone);
        logger.info("Message: {}", message);
        logger.info("Service Twilio activé: {}", enabled);

        if (!enabled) {
            logger.info("WhatsApp désactivé (simulé vers: {})", toPhone);
            logger.info("=== Fin envoi WhatsApp (simulé) ===");
            return true;
        }

        ensureInitialized();
        if (!initialized) {
            logger.warn("Impossible d'envoyer WhatsApp: Twilio non initialisé");
            logger.warn("Account SID configuré: {}", accountSid != null && !accountSid.isBlank() ? "OUI" : "NON");
            logger.warn("Auth Token configuré: {}", authToken != null && !authToken.isBlank() ? "OUI" : "NON");
            logger.warn("From Number configuré: {}", fromNumber != null && !fromNumber.isBlank() ? fromNumber : "NON");
            logger.info("=== Fin envoi WhatsApp (échec initialisation) ===");
            return false;
        }

        try {
            String normalizedTo = normalizePhoneNumber(toPhone);
            String whatsappTo = "whatsapp:" + normalizedTo;
            String whatsappFrom = "whatsapp:" + fromNumber;

            logger.info("Numéro normalisé: {}", normalizedTo);
            logger.info("WhatsApp To: {}", whatsappTo);
            logger.info("WhatsApp From: {}", whatsappFrom);
            logger.info("Tentative d'envoi WhatsApp via Twilio...");

            Message msg = Message.creator(
                new PhoneNumber(whatsappTo),
                new PhoneNumber(whatsappFrom),
                message
            ).create();

            logger.info("✅ WhatsApp envoyé avec succès");
            logger.info("SID du message: {}", msg.getSid());
            logger.info("Statut: {}", msg.getStatus());
            logger.info("=== Fin envoi WhatsApp (succès) ===");
            return true;
        } catch (Exception e) {
            logger.error("❌ Erreur lors de l'envoi WhatsApp vers {}", toPhone);
            logger.error("Type d'erreur: {}", e.getClass().getSimpleName());
            logger.error("Message d'erreur: {}", e.getMessage());
            logger.info("=== Fin envoi WhatsApp (échec) ===");
            return false;
        }
    }

    private String normalizePhoneNumber(String phone) {
        if (phone == null || phone.isBlank()) return "";
        String cleaned = phone.replaceAll("[^0-9+]", "");
        if (cleaned.startsWith("+")) return cleaned;
        if (cleaned.startsWith("225")) return "+" + cleaned;
        return "+225" + cleaned;
    }
}
