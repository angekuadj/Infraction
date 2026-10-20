package ci.circulation.api.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "infraction_types")
public class InfractionType {
    @Id
    private String id;

    @Column(nullable = false)
    private String nom;

    private String description;
    private String category;
    private Integer ordre;

    @Column(nullable = false)
    private boolean actif = true;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Integer getOrdre() { return ordre; }
    public void setOrdre(Integer ordre) { this.ordre = ordre; }
    public boolean isActif() { return actif; }
    public void setActif(boolean actif) { this.actif = actif; }
}
