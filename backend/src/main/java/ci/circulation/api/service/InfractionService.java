package ci.circulation.api.service;

import ci.circulation.api.common.ApiException;
import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.Infraction;
import ci.circulation.api.domain.User;
import ci.circulation.api.repo.InfractionRepository;
import ci.circulation.api.repo.UserRepository;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class InfractionService {

    private final InfractionRepository infractions;
    private final FileStorageService storage;
    private final NotificationService notifications;
    private final UserRepository users;
    private final SmsService sms;

    public InfractionService(InfractionRepository infractions,
                             FileStorageService storage,
                             NotificationService notifications,
                             UserRepository users,
                             SmsService sms) {
        this.infractions = infractions;
        this.storage = storage;
        this.notifications = notifications;
        this.users = users;
        this.sms = sms;
    }

    @Transactional
    public Infraction create(User user,
                             Map<String, String> fields,
                             MultipartFile video,
                             MultipartFile photo,
                             MultipartFile plate,
                             String baseUrl) {
        // Seuls user, proprietaire et police_terrain peuvent créer des signalements
        if (!canCreateInfraction(user)) {
            throw ApiException.forbidden("Seuls les profils User, Propriétaire et Police Terrain peuvent créer des signalements.");
        }

        Infraction i = new Infraction();
        i.setId(UUID.randomUUID().toString());
        i.setLocalId(firstNonBlank(fields.get("localId"), fields.get("local_id")));
        i.setTypeId(firstNonBlank(fields.get("typeId"), fields.get("type_id"), fields.get("type")));
        i.setInciviTypeId(firstNonBlank(fields.get("inciviTypeId"), fields.get("incivi_type_id"),
                i.getTypeId()));
        i.setPlaqueImmatriculation(firstNonBlank(fields.get("plaqueImmatriculation"),
                fields.get("plaque_immatriculation"), fields.get("plaque")));
        i.setNumeroImmatriculation(firstNonBlank(fields.get("numeroImmatriculation"),
                fields.get("numero_immatriculation"), i.getPlaqueImmatriculation()));
        i.setDescription(firstNonBlank(fields.get("description"), fields.get("commentaire"),
                fields.get("comment")));
        i.setCommentaire(firstNonBlank(fields.get("commentaire"), fields.get("comment")));
        i.setLieu(firstNonBlank(fields.get("lieu"), fields.get("address"), fields.get("adresse")));
        i.setLatitude(parseDouble(fields.get("latitude")));
        i.setLongitude(parseDouble(fields.get("longitude")));
        i.setTrimStart(fields.get("trimStart"));
        i.setTrimEnd(fields.get("trimEnd"));
        i.setPanneStart(fields.get("panneStart"));
        i.setPanneEnd(fields.get("panneEnd"));
        i.setEnPanne(parseBool(fields.get("enPanne")));
        i.setStatus("pending");
        i.setPriority(firstNonBlank(fields.get("priority"), "normale"));

        i.setUserId(user.getId());
        i.setUserName(DtoMapper.displayName(user));
        i.setClientId(user.getId());
        i.setClientName(DtoMapper.displayName(user));
        if (SecurityUtils.isPrivileged(user)) {
            i.setAgentName(DtoMapper.displayName(user));
            i.setAgentPolice(user.getAgentPolice());
        }

        storeFile(i, video, "video", baseUrl);
        storeFile(i, photo, "photo", baseUrl);
        storeFile(i, plate, "plate", baseUrl);

        if (i.getPlaqueImmatriculation() == null || i.getPlaqueImmatriculation().isBlank()) {
            // Un citoyen (user / propriétaire) doit toujours être relié à sa plaque.
            if (SecurityUtils.isCitizen(user)) {
                i.setPlaqueImmatriculation(user.getPlaqueImmatriculation());
                i.setNumeroImmatriculation(user.getNumeroImmatriculation());
            }
        }

        Infraction saved = infractions.save(i);
        notifications.create(user.getId(), "Signalement enregistré",
                "Votre signalement a bien été reçu et sera traité.", "infraction");
        return saved;
    }

    private void storeFile(Infraction i, MultipartFile file, String kind, String baseUrl) {
        String name = storage.store(file);
        if (name == null) return;
        String path = "/uploads/" + name;
        String url = baseUrl + path;
        switch (kind) {
            case "video" -> {
                i.setVideoPath(path);
                i.setVideoUrl(url);
            }
            case "photo" -> {
                i.setPhotoPath(path);
                i.setImageUrl(url);
            }
            case "plate" -> i.setPlateImagePath(path);
            default -> { }
        }
    }

    public List<Infraction> list(User user) {
        if (SecurityUtils.isPrivileged(user)) {
            // Agent de police : ne voit que les infractions validées par l'agent équipu
            if (SecurityUtils.isAgentPolice(user)) {
                return infractions.findByStatusInOrderByCreatedAtDesc(
                    List.of("validated", "confirmed")
                );
            }
            // Autres agents (admin, superviseur, agent_quipux, etc.) : voient tout
            return infractions.findAllByOrderByCreatedAtDesc();
        }
        if (SecurityUtils.isCitizen(user)
                && user.getPlaqueImmatriculation() != null
                && !user.getPlaqueImmatriculation().isBlank()) {
            return infractions.findByPlaqueImmatriculationOrderByCreatedAtDesc(
                    user.getPlaqueImmatriculation());
        }
        return infractions.findByUserIdOrderByCreatedAtDesc(user.getId());
    }

    public List<Infraction> forPlaque(User user, String plaque) {
        String value = firstNonBlank(plaque, user.getPlaqueImmatriculation());
        if (value == null || value.isBlank()) {
            throw ApiException.badRequest("Plaque d'immatriculation requise.");
        }
        return infractions.findByPlaqueImmatriculationOrderByCreatedAtDesc(value);
    }

    public Infraction get(User user, String id) {
        Infraction i = infractions.findById(id)
                .orElseThrow(() -> ApiException.notFound("Signalement introuvable."));
        if (!SecurityUtils.isPrivileged(user) && !user.getId().equals(i.getUserId())) {
            throw ApiException.forbidden("Accès refusé à ce signalement.");
        }
        // Vérifier si le signalement est verrouillé par un autre agent
        if (i.getLockedByUserId() != null && !i.getLockedByUserId().equals(user.getId())) {
            throw ApiException.forbidden("Ce signalement est en cours de traitement par un autre agent.");
        }
        return i;
    }

    @Transactional
    public void delete(User user, String id) {
        Infraction i = get(user, id);
        if (!SecurityUtils.isPrivileged(user) && !user.getId().equals(i.getUserId())) {
            throw ApiException.forbidden("Suppression non autorisée.");
        }
        infractions.delete(i);
    }

    @Transactional
    public Infraction updateStatus(User user, String id, String status) {
        if (!SecurityUtils.isPrivileged(user)) {
            throw ApiException.forbidden("Seuls les agents peuvent changer le statut.");
        }
        if (status == null || status.isBlank()) {
            throw ApiException.badRequest("Statut requis.");
        }
        Infraction i = get(user, id);
        i.setStatus(status.toLowerCase());
        i.setAgentName(DtoMapper.displayName(user));

        // Enregistrer le nom de l'agent selon son rôle
        if (SecurityUtils.isAgentQuipux(user)) {
            i.setAgentQuipuxName(DtoMapper.displayName(user));
        } else if (SecurityUtils.isAgentPolice(user)) {
            i.setAgentPoliceName(DtoMapper.displayName(user));
        }

        // Verrouiller le signalement pour l'agent qui le traite
        i.setLockedBy(user.getId());
        i.setLockedByUserId(user.getId());
        i.setLockedAt(Instant.now());
        Infraction saved = infractions.save(i);

        // Notifier le reporter du signalement
        if (i.getUserId() != null) {
            notifications.create(i.getUserId(), "Signalement mis à jour",
                    "Le statut de votre signalement est désormais : " + status + ".", "infraction");
        }

        // Si validé par l'agent, notifier le propriétaire de la plaque
        if ("validated".equalsIgnoreCase(status) || "confirmed".equalsIgnoreCase(status)) {
            notifyPlateOwner(i, status);
        }

        return saved;
    }

    private void notifyPlateOwner(Infraction infraction, String status) {
        String plaque = infraction.getPlaqueImmatriculation();
        if (plaque == null || plaque.isBlank()) {
            System.out.println("⚠️ Notification propriétaire annulée : plaque vide");
            return;
        }

        System.out.println("🔔 Début notification propriétaire de la plaque: " + plaque);
        System.out.println("Statut de l'infraction: " + status);

        // Normaliser la plaque pour la recherche
        String normalizedPlaque = plaque.toUpperCase().replaceAll("[^A-Z0-9]", "");
        System.out.println("Plaque normalisée pour recherche: " + normalizedPlaque);

        // Chercher le propriétaire
        Optional<User> ownerOpt = users.findByPlaqueImmatriculation(normalizedPlaque);
        if (ownerOpt.isEmpty()) {
            // Essayer avec une recherche partielle
            System.out.println("🔍 Recherche exacte infructueuse, tentative recherche partielle...");
            List<User> candidates = users.findByPlaqueImmatriculationContainingIgnoreCase(normalizedPlaque);
            if (!candidates.isEmpty()) {
                ownerOpt = Optional.of(candidates.get(0));
                System.out.println("✅ Propriétaire trouvé via recherche partielle");
            }
        } else {
            System.out.println("✅ Propriétaire trouvé via recherche exacte");
        }

        if (ownerOpt.isEmpty()) {
            System.out.println("❌ Aucun propriétaire trouvé pour la plaque: " + plaque);
            return; // Aucun propriétaire trouvé
        }

        User owner = ownerOpt.get();
        System.out.println("👤 Propriétaire: " + owner.getNom() + " " + owner.getPrenom());
        System.out.println("📱 Téléphone: " + (owner.getPhone() != null ? owner.getPhone() : "NON DEFINI"));

        // Notifier dans l'application
        String title = "Infraction validée sur votre véhicule";
        String body = String.format(
            "Une infraction concernant votre plaque %s a été validée par la police. Veuillez consulter l'application pour plus de détails.",
            plaque
        );
        notifications.create(owner.getId(), title, body, "infraction");
        System.out.println("📲 Notification app créée pour l'utilisateur: " + owner.getId());

        // Envoyer SMS
        if (owner.getPhone() != null && !owner.getPhone().isBlank()) {
            String smsMessage = String.format(
                "CIRCULATION CI: Une infraction concernant votre plaque %s a été validée. Connectez-vous à l'application pour plus d'informations.",
                plaque
            );
            System.out.println("📨 Envoi SMS au numéro: " + owner.getPhone());
            boolean smsSent = sms.sendSms(owner.getPhone(), smsMessage);
            System.out.println("SMS envoyé: " + (smsSent ? "✅ OUI" : "❌ NON"));
        } else {
            System.out.println("⚠️ SMS non envoyé : numéro de téléphone absent");
        }

        // Envoyer WhatsApp
        if (owner.getPhone() != null && !owner.getPhone().isBlank()) {
            String whatsappMessage = String.format(
                "🚗 *CIRCULATION CI*\n\nUne infraction concernant votre plaque *%s* a été validée par la police.\n\nVeuillez consulter l'application pour plus de détails.",
                plaque
            );
            System.out.println("💬 Envoi WhatsApp au numéro: " + owner.getPhone());
            boolean whatsappSent = sms.sendWhatsApp(owner.getPhone(), whatsappMessage);
            System.out.println("WhatsApp envoyé: " + (whatsappSent ? "✅ OUI" : "❌ NON"));
        } else {
            System.out.println("⚠️ WhatsApp non envoyé : numéro de téléphone absent");
        }

        System.out.println("🔔 Fin notification propriétaire");
    }

    public Map<String, Object> findPlateOwner(User user, String plaque) {
        if (!SecurityUtils.isPrivileged(user)) {
            throw ApiException.forbidden("Seuls les agents peuvent rechercher le propriétaire d'une plaque.");
        }
        if (plaque == null || plaque.isBlank()) {
            throw ApiException.badRequest("Plaque requise.");
        }

        String normalizedPlaque = plaque.toUpperCase().replaceAll("[^A-Z0-9]", "");

        Optional<User> ownerOpt = users.findByPlaqueImmatriculation(normalizedPlaque);
        if (ownerOpt.isEmpty()) {
            List<User> candidates = users.findByPlaqueImmatriculationContainingIgnoreCase(normalizedPlaque);
            if (!candidates.isEmpty()) {
                ownerOpt = Optional.of(candidates.get(0));
            }
        }

        if (ownerOpt.isEmpty()) {
            Map<String, Object> result = new LinkedHashMap<>();
            result.put("found", false);
            result.put("message", "Aucun propriétaire trouvé pour cette plaque");
            return result;
        }

        User owner = ownerOpt.get();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("found", true);
        result.put("owner", DtoMapper.userSummary(owner));
        return result;
    }

    @Transactional
    public Infraction lock(User user, String id) {
        Infraction i = get(user, id);
        if (i.getLockedBy() != null && !i.getLockedBy().equals(user.getId())) {
            throw ApiException.forbidden("Ce signalement est déjà verrouillé par un autre agent.");
        }
        i.setLockedBy(user.getId());
        i.setLockedByUserId(user.getId());
        i.setLockedAt(Instant.now());
        return infractions.save(i);
    }

    @Transactional
    public Infraction unlock(User user, String id) {
        Infraction i = get(user, id);
        if (i.getLockedBy() != null && !i.getLockedBy().equals(user.getId())) {
            throw ApiException.forbidden("Seul l'agent qui a verrouillé peut déverrouiller.");
        }
        i.setLockedBy(null);
        i.setLockedByUserId(null);
        i.setLockedAt(null);
        return infractions.save(i);
    }

    @Transactional
    public Infraction updatePlate(User user, String id, String plaque) {
        if (plaque == null || plaque.isBlank()) {
            throw ApiException.badRequest("Plaque d'immatriculation requise.");
        }
        Infraction i = get(user, id);
        // Agent équipu peut modifier la plaque des signalements en attente
        if (!SecurityUtils.isPrivileged(user) && !user.getId().equals(i.getUserId())) {
            if (!SecurityUtils.isAgentQuipux(user) || !"pending".equals(i.getStatus())) {
                throw ApiException.forbidden("Modification non autorisée.");
            }
        }
        String normalized = plaque.trim().toUpperCase();
        i.setPlaqueImmatriculation(normalized);
        i.setNumeroImmatriculation(normalized);
        i.setAgentName(DtoMapper.displayName(user));
        return infractions.save(i);
    }

    public Map<String, Object> data(Infraction i) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("data", DtoMapper.infraction(i));
        return body;
    }

    private static String firstNonBlank(String... values) {
        for (String v : values) {
            if (v != null && !v.isBlank()) return v;
        }
        return null;
    }

    private static Double parseDouble(String v) {
        if (v == null || v.isBlank()) return null;
        try { return Double.parseDouble(v); } catch (NumberFormatException e) { return null; }
    }

    private static boolean parseBool(String v) {
        return v != null && (v.equalsIgnoreCase("true") || v.equals("1"));
    }

    private static boolean canCreateInfraction(User user) {
        return switch (role(user)) {
            case "user", "proprietaire", "police_terrain" -> true;
            default -> false;
        };
    }

    private static String role(User user) {
        return user.getRole() == null ? "" : user.getRole().toLowerCase().trim();
    }
}
