-- Migration pour créer les tables d'archivage
-- Ces tables stockent les infractions et réclamations archivées

-- Table des infractions archivées
CREATE TABLE IF NOT EXISTS infractions_archived (
    id VARCHAR(255) PRIMARY KEY,
    local_id VARCHAR(255),
    type_id VARCHAR(255),
    incivi_type_id VARCHAR(255),
    plaque_immatriculation VARCHAR(255),
    numero_immatriculation VARCHAR(255),
    description TEXT,
    commentaire TEXT,
    lieu VARCHAR(255),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    priority VARCHAR(50),
    video_path VARCHAR(255),
    photo_path VARCHAR(255),
    plate_image_path VARCHAR(255),
    thumbnail_path VARCHAR(255),
    video_url VARCHAR(500),
    image_url VARCHAR(500),
    client_id VARCHAR(255),
    client_name VARCHAR(255),
    user_id VARCHAR(255),
    user_name VARCHAR(255),
    agent_name VARCHAR(255),
    agent_police VARCHAR(255),
    agent_quipux_name VARCHAR(255),
    agent_police_name VARCHAR(255),
    locked_by VARCHAR(255),
    locked_by_user_id VARCHAR(255),
    locked_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    reported_at TIMESTAMP,
    sent_at TIMESTAMP,
    retry_count INTEGER,
    trim_start VARCHAR(255),
    trim_end VARCHAR(255),
    score DOUBLE PRECISION,
    panne_start VARCHAR(255),
    panne_end VARCHAR(255),
    en_panne BOOLEAN NOT NULL DEFAULT FALSE,
    archived_at TIMESTAMP NOT NULL,
    archived_by VARCHAR(255),
    archived_reason TEXT
);

-- Table des réclamations archivées
CREATE TABLE IF NOT EXISTS reclamations_archived (
    id VARCHAR(255) PRIMARY KEY,
    subject VARCHAR(255),
    message TEXT,
    status VARCHAR(50),
    statut VARCHAR(50),
    client_id VARCHAR(255),
    client_name VARCHAR(255),
    user_id VARCHAR(255),
    user_name VARCHAR(255),
    assigned_to VARCHAR(255),
    agent_name VARCHAR(255),
    closed BOOLEAN NOT NULL DEFAULT FALSE,
    closed_at TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    archived_at TIMESTAMP NOT NULL,
    archived_by VARCHAR(255),
    archived_reason TEXT
);

-- Index pour améliorer les performances des requêtes sur les archives
CREATE INDEX IF NOT EXISTS idx_infractions_archived_archived_at ON infractions_archived(archived_at DESC);
CREATE INDEX IF NOT EXISTS idx_infractions_archived_plaque ON infractions_archived(plaque_immatriculation);
CREATE INDEX IF NOT EXISTS idx_infractions_archived_status ON infractions_archived(status);
CREATE INDEX IF NOT EXISTS idx_reclamations_archived_archived_at ON reclamations_archived(archived_at DESC);
CREATE INDEX IF NOT EXISTS idx_reclamations_archived_client ON reclamations_archived(client_id);
CREATE INDEX IF NOT EXISTS idx_reclamations_archived_status ON reclamations_archived(status);
