-- Migration v5 : Autoriser la lecture publique/authentifiée de conscrits et conscrit_state pour le classement Leaderboard

-- 1. Table conscrits
ALTER TABLE public.conscrits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Les utilisateurs peuvent lire tous les conscrits" ON public.conscrits;
CREATE POLICY "Les utilisateurs peuvent lire tous les conscrits"
  ON public.conscrits FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own conscrits" ON public.conscrits;
CREATE POLICY "Users can insert their own conscrits"
  ON public.conscrits FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 2. Table conscrit_state
ALTER TABLE public.conscrit_state ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own conscrit state" ON public.conscrit_state;
DROP POLICY IF EXISTS "Les utilisateurs peuvent lire tous les conscrit_state" ON public.conscrit_state;
CREATE POLICY "Les utilisateurs meuvent lire tous les conscrit_state"
  ON public.conscrit_state FOR SELECT
  USING (true);

-- 3. Table profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Les utilisateurs peuvent lire tous les profils" ON public.profiles;
CREATE POLICY "Les utilisateurs peuvent lire tous les profils"
  ON public.profiles FOR SELECT
  USING (true);
