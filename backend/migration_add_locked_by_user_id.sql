-- Migration pour ajouter le champ lockedByUserId à la table infractions
-- Cette migration est gérée automatiquement par JPA (ddl-auto: update)
-- mais ce fichier documente le changement de schéma

ALTER TABLE infractions ADD COLUMN IF NOT EXISTS locked_by_user_id VARCHAR(255);
