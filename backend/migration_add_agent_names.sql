-- Migration pour ajouter les colonnes agentQuipuxName et agentPoliceName
-- Ces colonnes permettront de suivre quels agents ont traité le signalement

ALTER TABLE infractions ADD COLUMN agent_quipux_name VARCHAR(255);
ALTER TABLE infractions ADD COLUMN agent_police_name VARCHAR(255);
