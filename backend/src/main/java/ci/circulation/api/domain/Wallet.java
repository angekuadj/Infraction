package ci.circulation.api.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "wallets")
public class Wallet {
    @Id
    private String id;

    @Column(name = "user_id")
    private String userId;

    @Column(nullable = false)
    private double solde = 0;

    private Instant updatedAt;

    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "wallet_id")
    private List<WalletOperation> operations = new ArrayList<>();

    @PrePersist
    void onCreate() { if (updatedAt == null) updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public double getSolde() { return solde; }
    public void setSolde(double solde) { this.solde = solde; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
    public List<WalletOperation> getOperations() { return operations; }
    public void setOperations(List<WalletOperation> operations) { this.operations = operations; }
}
