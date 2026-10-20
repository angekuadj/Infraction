package ci.circulation.api.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "wallet_operations")
public class WalletOperation {
    @Id
    private String id;

    private String type;
    private double amount;
    private String description;
    private String label;
    private Instant date;
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = Instant.now();
        if (date == null) date = createdAt;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }
    public Instant getDate() { return date; }
    public void setDate(Instant date) { this.date = date; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
