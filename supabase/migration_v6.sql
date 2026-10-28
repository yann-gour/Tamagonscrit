-- Migration v6 : Ajout des colonnes de personnalisation de l'avatar conscrit dans public.profiles

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_state text DEFAULT 'idle',
  ADD COLUMN IF NOT EXISTS avatar_skin_color text DEFAULT '#E5AA7A',
  ADD COLUMN IF NOT EXISTS avatar_hair_color text DEFAULT '#9C5A3C';

-- Mettre à jour la fonction trigger handle_user_profile_update pour inclure ces champs si présents dans metadata
CREATE OR REPLACE FUNCTION public.handle_user_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, bucque, fams, tabagns, proms,
    avatar_state, avatar_skin_color, avatar_hair_color, updated_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'bucque', ''),
    NEW.raw_user_meta_data->>'fams',
    NEW.raw_user_meta_data->>'tabagns',
    (NEW.raw_user_meta_data->>'proms')::integer,
    COALESCE(NEW.raw_user_meta_data->>'avatar_state', 'idle'),
    COALESCE(NEW.raw_user_meta_data->>'avatar_skin_color', '#E5AA7A'),
    COALESCE(NEW.raw_user_meta_data->>'avatar_hair_color', '#9C5A3C'),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    bucque = EXCLUDED.bucque,
    fams = EXCLUDED.fams,
    tabagns = EXCLUDED.tabagns,
    proms = EXCLUDED.proms,
    avatar_state = COALESCE(EXCLUDED.avatar_state, public.profiles.avatar_state),
    avatar_skin_color = COALESCE(EXCLUDED.avatar_skin_color, public.profiles.avatar_skin_color),
    avatar_hair_color = COALESCE(EXCLUDED.avatar_hair_color, public.profiles.avatar_hair_color),
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
