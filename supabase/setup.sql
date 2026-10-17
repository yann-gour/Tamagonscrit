-- 1. Création de la table pour stocker l'état du conscrit
CREATE TABLE public.conscrit_state (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  energie float8 NOT NULL DEFAULT 100.0,
  birse float8 NOT NULL DEFAULT 0.0,
  trads float8 NOT NULL DEFAULT 0.0,
  current_gif text NOT NULL DEFAULT 'conscrit.gif',
  PRIMARY KEY (user_id)
);

-- 2. Activation de la sécurité au niveau des lignes (Row Level Security)
ALTER TABLE public.conscrit_state ENABLE ROW LEVEL SECURITY;

-- 3. Politiques d'accès (Un utilisateur ne peut lire et modifier que son propre état)
CREATE POLICY "Users can view their own conscrit state"
  ON public.conscrit_state FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conscrit state"
  ON public.conscrit_state FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conscrit state"
  ON public.conscrit_state FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
