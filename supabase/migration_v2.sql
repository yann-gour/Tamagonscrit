-- Migration pour ajouter la gestion du temps au Conscrit

-- 1. Ajout des colonnes pour l'activité en cours et le temps
ALTER TABLE public.conscrit_state
ADD COLUMN activity text NOT NULL DEFAULT 'idle',
ADD COLUMN last_updated timestamptz NOT NULL DEFAULT now();

-- 2. Fonction et Trigger pour mettre à jour automatiquement `last_updated`
-- (Optionnel si on gère tout via Flutter, mais sécuritaire pour la cohérence)
CREATE OR REPLACE FUNCTION update_last_updated_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conscrit_state_modtime
    BEFORE UPDATE ON public.conscrit_state
    FOR EACH ROW
    EXECUTE PROCEDURE update_last_updated_column();
