package ci.circulation.api.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "users")
public class User {
    @Id
    private String id;

    private String nom;
    private String prenom;
    private String email;
    private String phone;
    private String password;

    @Column(nullable = false)
    private String role;

    private String plaqueImmatriculation;
    private String numeroImmatriculation;
    private String matricule;
    private String agentPolice;

    private String cni;
    private String cniPhotoPath;

    @Column(nullable = false)
    private boolean active = true;

    @Column(nullable = false)
    private boolean enPanne = false;

    private Instant panneStart;
    private Instant panneEnd;

    private Instant createdAt;
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = Instant.now();
        updatedAt = Instant.now();
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public String getPlaqueImmatriculation() { return plaqueImmatriculation; }
    public void setPlaqueImmatriculation(String v) { this.plaqueImmatriculation = v; }
    public String getNumeroImmatriculation() { return numeroImmatriculation; }
    public void setNumeroImmatriculation(String v) { this.numeroImmatriculation = v; }
    public String getMatricule() { return matricule; }
    public void setMatricule(String matricule) { this.matricule = matricule; }
    public String getAgentPolice() { return agentPolice; }
    public void setAgentPolice(String agentPolice) { this.agentPolice = agentPolice; }
    public String getCni() { return cni; }
    public void setCni(String cni) { this.cni = cni; }
    public String getCniPhotoPath() { return cniPhotoPath; }
    public void setCniPhotoPath(String cniPhotoPath) { this.cniPhotoPath = cniPhotoPath; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public boolean isEnPanne() { return enPanne; }
    public void setEnPanne(boolean enPanne) { this.enPanne = enPanne; }
    public Instant getPanneStart() { return panneStart; }
    public void setPanneStart(Instant panneStart) { this.panneStart = panneStart; }
    public Instant getPanneEnd() { return panneEnd; }
    public void setPanneEnd(Instant panneEnd) { this.panneEnd = panneEnd; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
