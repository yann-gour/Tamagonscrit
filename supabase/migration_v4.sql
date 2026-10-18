-- Migration v4 : Création de la table profiles et synchronisation avec auth.users metadata

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  bucque text NOT NULL,
  fams text,
  tabagns text,
  proms integer,
  updated_at timestamptz DEFAULT now()
);

-- Activation de la sécurité au niveau des lignes (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Les utilisateurs peuvent lire tous les profils"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Les utilisateurs peuvent modifier leur propre profil"
  ON public.profiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Fonction Trigger pour copier automatiquement les metadata depuis auth.users vers public.profiles
CREATE OR REPLACE FUNCTION public.handle_user_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, bucque, fams, tabagns, proms, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'bucque', ''),
    NEW.raw_user_meta_data->>'fams',
    NEW.raw_user_meta_data->>'tabagns',
    (NEW.raw_user_meta_data->>'proms')::integer,
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    bucque = EXCLUDED.bucque,
    fams = EXCLUDED.fams,
    tabagns = EXCLUDED.tabagns,
    proms = EXCLUDED.proms,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger sur la table auth.users
DROP TRIGGER IF EXISTS on_auth_user_updated_profile ON auth.users;
CREATE TRIGGER on_auth_user_updated_profile
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_user_profile_update();
