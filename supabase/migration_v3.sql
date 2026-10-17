-- Ajout de la date de première action pour mesurer le temps jusqu'à 100 birse
ALTER TABLE public.conscrit_state
ADD COLUMN start_time timestamptz;
