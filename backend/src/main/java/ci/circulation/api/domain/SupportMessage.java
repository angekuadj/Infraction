package ci.circulation.api.domain;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "support_messages")
public class SupportMessage {
    @Id
    private String id;

    @Column(name = "reclamation_id")
    private String reclamationId;

    private String sender;
    private String senderName;
    private String receiver;
    private String body;

    @Column(nullable = false)
    private boolean fromClient = false;

    @Column(nullable = false)
    private boolean fromAgent = false;

    private Instant createdAt;

    @PrePersist
    void onCreate() { if (createdAt == null) createdAt = Instant.now(); }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getReclamationId() { return reclamationId; }
    public void setReclamationId(String reclamationId) { this.reclamationId = reclamationId; }
    public String getSender() { return sender; }
    public void setSender(String sender) { this.sender = sender; }
    public String getSenderName() { return senderName; }
    public void setSenderName(String senderName) { this.senderName = senderName; }
    public String getReceiver() { return receiver; }
    public void setReceiver(String receiver) { this.receiver = receiver; }
    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }
    public boolean isFromClient() { return fromClient; }
    public void setFromClient(boolean fromClient) { this.fromClient = fromClient; }
    public boolean isFromAgent() { return fromAgent; }
    public void setFromAgent(boolean fromAgent) { this.fromAgent = fromAgent; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
