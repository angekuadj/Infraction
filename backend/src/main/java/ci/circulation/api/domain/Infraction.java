package ci.circulation.api.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "infractions")
public class Infraction {
    @Id
    private String id;

    private String localId;
    private String typeId;
    private String inciviTypeId;
    private String plaqueImmatriculation;
    private String numeroImmatriculation;
    private String description;
    private String commentaire;
    private String lieu;
    private Double latitude;
    private Double longitude;

    @Column(nullable = false)
    private String status = "pending";

    private String priority;
    private String videoPath;
    private String photoPath;
    private String plateImagePath;
    private String thumbnailPath;
    private String videoUrl;
    private String imageUrl;

    private String clientId;
    private String clientName;
    private String userId;
    private String userName;
    private String agentName;
    private String agentPolice;
    private String agentQuipuxName;
    private String agentPoliceName;

    private String lockedBy;
    private String lockedByUserId;
    private Instant lockedAt;

    private Instant createdAt;
    private Instant updatedAt;
    private Instant reportedAt;
    private Instant sentAt;
    private Integer retryCount;

    private String trimStart;
    private String trimEnd;
    private Double score;
    private String panneStart;
    private String panneEnd;

    @Column(nullable = false)
    private boolean enPanne = false;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = Instant.now();
        if (reportedAt == null) reportedAt = Instant.now();
        updatedAt = Instant.now();
    }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getLocalId() { return localId; }
    public void setLocalId(String localId) { this.localId = localId; }
    public String getTypeId() { return typeId; }
    public void setTypeId(String typeId) { this.typeId = typeId; }
    public String getInciviTypeId() { return inciviTypeId; }
    public void setInciviTypeId(String inciviTypeId) { this.inciviTypeId = inciviTypeId; }
    public String getPlaqueImmatriculation() { return plaqueImmatriculation; }
    public void setPlaqueImmatriculation(String v) { this.plaqueImmatriculation = v; }
    public String getNumeroImmatriculation() { return numeroImmatriculation; }
    public void setNumeroImmatriculation(String v) { this.numeroImmatriculation = v; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCommentaire() { return commentaire; }
    public void setCommentaire(String commentaire) { this.commentaire = commentaire; }
    public String getLieu() { return lieu; }
    public void setLieu(String lieu) { this.lieu = lieu; }
    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
    public String getVideoPath() { return videoPath; }
    public void setVideoPath(String videoPath) { this.videoPath = videoPath; }
    public String getPhotoPath() { return photoPath; }
    public void setPhotoPath(String photoPath) { this.photoPath = photoPath; }
    public String getPlateImagePath() { return plateImagePath; }
    public void setPlateImagePath(String plateImagePath) { this.plateImagePath = plateImagePath; }
    public String getThumbnailPath() { return thumbnailPath; }
    public void setThumbnailPath(String thumbnailPath) { this.thumbnailPath = thumbnailPath; }
    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getClientId() { return clientId; }
    public void setClientId(String clientId) { this.clientId = clientId; }
    public String getClientName() { return clientName; }
    public void setClientName(String clientName) { this.clientName = clientName; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }
    public String getAgentName() { return agentName; }
    public void setAgentName(String agentName) { this.agentName = agentName; }
    public String getAgentPolice() { return agentPolice; }
    public void setAgentPolice(String agentPolice) { this.agentPolice = agentPolice; }
    public String getAgentQuipuxName() { return agentQuipuxName; }
    public void setAgentQuipuxName(String agentQuipuxName) { this.agentQuipuxName = agentQuipuxName; }
    public String getAgentPoliceName() { return agentPoliceName; }
    public void setAgentPoliceName(String agentPoliceName) { this.agentPoliceName = agentPoliceName; }
    public String getLockedBy() { return lockedBy; }
    public void setLockedBy(String lockedBy) { this.lockedBy = lockedBy; }
    public String getLockedByUserId() { return lockedByUserId; }
    public void setLockedByUserId(String lockedByUserId) { this.lockedByUserId = lockedByUserId; }
    public Instant getLockedAt() { return lockedAt; }
    public void setLockedAt(Instant lockedAt) { this.lockedAt = lockedAt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
    public Instant getReportedAt() { return reportedAt; }
    public void setReportedAt(Instant reportedAt) { this.reportedAt = reportedAt; }
    public Instant getSentAt() { return sentAt; }
    public void setSentAt(Instant sentAt) { this.sentAt = sentAt; }
    public Integer getRetryCount() { return retryCount; }
    public void setRetryCount(Integer retryCount) { this.retryCount = retryCount; }
    public String getTrimStart() { return trimStart; }
    public void setTrimStart(String trimStart) { this.trimStart = trimStart; }
    public String getTrimEnd() { return trimEnd; }
    public void setTrimEnd(String trimEnd) { this.trimEnd = trimEnd; }
    public Double getScore() { return score; }
    public void setScore(Double score) { this.score = score; }
    public String getPanneStart() { return panneStart; }
    public void setPanneStart(String panneStart) { this.panneStart = panneStart; }
    public String getPanneEnd() { return panneEnd; }
    public void setPanneEnd(String panneEnd) { this.panneEnd = panneEnd; }
    public boolean isEnPanne() { return enPanne; }
    public void setEnPanne(boolean enPanne) { this.enPanne = enPanne; }
}
