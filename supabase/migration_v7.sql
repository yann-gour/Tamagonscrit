-- Migration v7 : Ajout des couleurs de t-shirt et de pantalon dans public.profiles

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_tshirt_color text DEFAULT '#A8E61D',
  ADD COLUMN IF NOT EXISTS avatar_pants_color text DEFAULT '#709AD1';

-- Mettre à jour la fonction trigger handle_user_profile_update
CREATE OR REPLACE FUNCTION public.handle_user_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, bucque, fams, tabagns, proms,
    avatar_state, avatar_skin_color, avatar_hair_color,
    avatar_tshirt_color, avatar_pants_color, updated_at
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
    COALESCE(NEW.raw_user_meta_data->>'avatar_tshirt_color', '#A8E61D'),
    COALESCE(NEW.raw_user_meta_data->>'avatar_pants_color', '#709AD1'),
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
    avatar_tshirt_color = COALESCE(EXCLUDED.avatar_tshirt_color, public.profiles.avatar_tshirt_color),
    avatar_pants_color = COALESCE(EXCLUDED.avatar_pants_color, public.profiles.avatar_pants_color),
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
