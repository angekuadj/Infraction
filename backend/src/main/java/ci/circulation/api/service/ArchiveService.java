package ci.circulation.api.service;

import ci.circulation.api.common.ApiException;
import ci.circulation.api.common.DtoMapper;
import ci.circulation.api.common.SecurityUtils;
import ci.circulation.api.domain.Infraction;
import ci.circulation.api.domain.InfractionArchived;
import ci.circulation.api.domain.Reclamation;
import ci.circulation.api.domain.ReclamationArchived;
import ci.circulation.api.domain.User;
import ci.circulation.api.repo.InfractionArchivedRepository;
import ci.circulation.api.repo.InfractionRepository;
import ci.circulation.api.repo.ReclamationArchivedRepository;
import ci.circulation.api.repo.ReclamationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class ArchiveService {

    private static final Logger logger = LoggerFactory.getLogger(ArchiveService.class);

    private final InfractionRepository infractions;
    private final InfractionArchivedRepository infractionsArchived;
    private final ReclamationRepository reclamations;
    private final ReclamationArchivedRepository reclamationsArchived;

    @Value("${app.archive.enabled:true}")
    private boolean archiveEnabled;

    @Value("${app.archive.infraction-days:90}")
    private int infractionArchiveDays;

    @Value("${app.archive.reclamation-days:60}")
    private int reclamationArchiveDays;

    public ArchiveService(InfractionRepository infractions,
                          InfractionArchivedRepository infractionsArchived,
                          ReclamationRepository reclamations,
                          ReclamationArchivedRepository reclamationsArchived) {
        this.infractions = infractions;
        this.infractionsArchived = infractionsArchived;
        this.reclamations = reclamations;
        this.reclamationsArchived = reclamationsArchived;
    }

    /**
     * Tâche planifiée exécutée chaque nuit à 2h du matin
     * Archive les infractions et réclamations clôturées après le délai configuré
     */
    @Scheduled(cron = "${app.archive.cron:0 0 2 * * ?}")
    @Transactional
    public void archiveOldRecords() {
        if (!archiveEnabled) {
            logger.info("Archivage désactivé dans la configuration");
            return;
        }

        logger.info("Début de l'archivage automatique...");

        try {
            int infractionsArchived = archiveOldInfractions();
            int reclamationsArchived = archiveOldReclamations();

            logger.info("Archivage terminé: {} infractions, {} réclamations",
                infractionsArchived, reclamationsArchived);
        } catch (Exception e) {
            logger.error("Erreur lors de l'archivage automatique", e);
        }
    }

    /**
     * Archive les infractions clôturées (validée ou refusée) après le délai configuré
     */
    @Transactional
    public int archiveOldInfractions() {
        Instant cutoffDate = Instant.now().minusSeconds(infractionArchiveDays * 86400L);

        // Trouver les infractions à archiver
        List<Infraction> toArchive = infractions.findByStatusInAndUpdatedAtBefore(
            List.of("validee", "validated", "refusee", "rejected", "constatee", "confirmed"),
            cutoffDate
        );

        int count = 0;
        for (Infraction infraction : toArchive) {
            try {
                archiveInfraction(infraction, "system", "Auto-archive after " + infractionArchiveDays + " days");
                count++;
            } catch (Exception e) {
                logger.error("Erreur lors de l'archivage de l'infraction {}", infraction.getId(), e);
            }
        }

        return count;
    }

    /**
     * Archive les réclamations clôturées après le délai configuré
     */
    @Transactional
    public int archiveOldReclamations() {
        Instant cutoffDate = Instant.now().minusSeconds(reclamationArchiveDays * 86400L);

        // Trouver les réclamations à archiver
        List<Reclamation> toArchive = reclamations.findByClosedTrueAndUpdatedAtBefore(cutoffDate);

        int count = 0;
        for (Reclamation reclamation : toArchive) {
            try {
                archiveReclamation(reclamation, "system", "Auto-archive after " + reclamationArchiveDays + " days");
                count++;
            } catch (Exception e) {
                logger.error("Erreur lors de l'archivage de la réclamation {}", reclamation.getId(), e);
            }
        }

        return count;
    }

    /**
     * Archive une infraction spécifique
     */
    @Transactional
    public InfractionArchived archiveInfraction(Infraction infraction, String archivedBy, String reason) {
        // Créer l'entrée archivée
        InfractionArchived archived = new InfractionArchived();
        archived.setId(infraction.getId());
        archived.setLocalId(infraction.getLocalId());
        archived.setTypeId(infraction.getTypeId());
        archived.setInciviTypeId(infraction.getInciviTypeId());
        archived.setPlaqueImmatriculation(infraction.getPlaqueImmatriculation());
        archived.setNumeroImmatriculation(infraction.getNumeroImmatriculation());
        archived.setDescription(infraction.getDescription());
        archived.setCommentaire(infraction.getCommentaire());
        archived.setLieu(infraction.getLieu());
        archived.setLatitude(infraction.getLatitude());
        archived.setLongitude(infraction.getLongitude());
        archived.setStatus(infraction.getStatus());
        archived.setPriority(infraction.getPriority());
        archived.setVideoPath(infraction.getVideoPath());
        archived.setPhotoPath(infraction.getPhotoPath());
        archived.setPlateImagePath(infraction.getPlateImagePath());
        archived.setThumbnailPath(infraction.getThumbnailPath());
        archived.setVideoUrl(infraction.getVideoUrl());
        archived.setImageUrl(infraction.getImageUrl());
        archived.setClientId(infraction.getClientId());
        archived.setClientName(infraction.getClientName());
        archived.setUserId(infraction.getUserId());
        archived.setUserName(infraction.getUserName());
        archived.setAgentName(infraction.getAgentName());
        archived.setAgentPolice(infraction.getAgentPolice());
        archived.setAgentQuipuxName(infraction.getAgentQuipuxName());
        archived.setAgentPoliceName(infraction.getAgentPoliceName());
        archived.setLockedBy(infraction.getLockedBy());
        archived.setLockedByUserId(infraction.getLockedByUserId());
        archived.setLockedAt(infraction.getLockedAt());
        archived.setCreatedAt(infraction.getCreatedAt());
        archived.setUpdatedAt(infraction.getUpdatedAt());
        archived.setReportedAt(infraction.getReportedAt());
        archived.setSentAt(infraction.getSentAt());
        archived.setRetryCount(infraction.getRetryCount());
        archived.setTrimStart(infraction.getTrimStart());
        archived.setTrimEnd(infraction.getTrimEnd());
        archived.setScore(infraction.getScore());
        archived.setPanneStart(infraction.getPanneStart());
        archived.setPanneEnd(infraction.getPanneEnd());
        archived.setEnPanne(infraction.isEnPanne());
        archived.setArchivedBy(archivedBy);
        archived.setArchivedReason(reason);

        // Sauvegarder l'archive
        infractionsArchived.save(archived);

        // Supprimer l'original
        infractions.delete(infraction);

        logger.info("Infraction {} archivée par {}", infraction.getId(), archivedBy);
        return archived;
    }

    /**
     * Archive une réclamation spécifique
     */
    @Transactional
    public ReclamationArchived archiveReclamation(Reclamation reclamation, String archivedBy, String reason) {
        // Créer l'entrée archivée
        ReclamationArchived archived = new ReclamationArchived();
        archived.setId(reclamation.getId());
        archived.setSubject(reclamation.getSubject());
        archived.setMessage(reclamation.getMessage());
        archived.setStatus(reclamation.getStatus());
        archived.setStatut(reclamation.getStatus());
        archived.setClientId(reclamation.getClientId());
        archived.setClientName(reclamation.getClientName());
        archived.setUserId(reclamation.getUserId());
        archived.setUserName(reclamation.getUserName());
        archived.setAssignedTo(reclamation.getAssignedTo());
        archived.setAgentName(reclamation.getAgentName());
        archived.setClosed(reclamation.isClosed());
        archived.setClosedAt(reclamation.getClosedAt());
        archived.setCreatedAt(reclamation.getCreatedAt());
        archived.setUpdatedAt(reclamation.getUpdatedAt());
        archived.setArchivedBy(archivedBy);
        archived.setArchivedReason(reason);

        // Sauvegarder l'archive
        reclamationsArchived.save(archived);

        // Supprimer l'original
        reclamations.delete(reclamation);

        logger.info("Réclamation {} archivée par {}", reclamation.getId(), archivedBy);
        return archived;
    }

    /**
     * Archive manuelle d'une infraction par un admin
     */
    @Transactional
    public InfractionArchived archiveInfractionById(User user, String id, String reason) {
        if (!SecurityUtils.isPrivileged(user)) {
            throw ApiException.forbidden("Seuls les admins peuvent archiver des dossiers.");
        }

        Infraction infraction = infractions.findById(id)
            .orElseThrow(() -> ApiException.notFound("Infraction introuvable."));

        return archiveInfraction(infraction, DtoMapper.displayName(user), reason);
    }

    /**
     * Archive manuelle d'une réclamation par un admin
     */
    @Transactional
    public ReclamationArchived archiveReclamationById(User user, String id, String reason) {
        if (!SecurityUtils.isPrivileged(user)) {
            throw ApiException.forbidden("Seuls les admins peuvent archiver des dossiers.");
        }

        Reclamation reclamation = reclamations.findById(id)
            .orElseThrow(() -> ApiException.notFound("Réclamation introuvable."));

        return archiveReclamation(reclamation, DtoMapper.displayName(user), reason);
    }

    public List<InfractionArchived> listArchivedInfractions(User user) {
        if (!SecurityUtils.isPrivileged(user)) {
            throw ApiException.forbidden("Accès refusé.");
        }
        return infractionsArchived.findAllByOrderByArchivedAtDesc();
    }

    public List<ReclamationArchived> listArchivedReclamations(User user) {
        if (!SecurityUtils.isPrivileged(user)) {
            throw ApiException.forbidden("Accès refusé.");
        }
        return reclamationsArchived.findAllByOrderByArchivedAtDesc();
    }
}
