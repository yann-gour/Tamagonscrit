-- Migration v10 : Ajout du skin équipé de l'avatar (avatar_equipped_skin) dans public.profiles

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_equipped_skin text DEFAULT 'none';

-- Mettre à jour la fonction trigger handle_user_profile_update
CREATE OR REPLACE FUNCTION public.handle_user_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, bucque, fams, tabagns, proms,
    brousoufs, zloeils,
    avatar_state, avatar_skin_color, avatar_hair_color,
    avatar_tshirt_color, avatar_pants_color, avatar_is_biaude_white, avatar_equipped_skin, updated_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'bucque', ''),
    NEW.raw_user_meta_data->>'fams',
    NEW.raw_user_meta_data->>'tabagns',
    (NEW.raw_user_meta_data->>'proms')::integer,
    COALESCE((NEW.raw_user_meta_data->>'brousoufs')::integer, 0),
    COALESCE((NEW.raw_user_meta_data->>'zloeils')::integer, 0),
    COALESCE(NEW.raw_user_meta_data->>'avatar_state', 'idle'),
    COALESCE(NEW.raw_user_meta_data->>'avatar_skin_color', '#E5AA7A'),
    COALESCE(NEW.raw_user_meta_data->>'avatar_hair_color', '#9C5A3C'),
    COALESCE(NEW.raw_user_meta_data->>'avatar_tshirt_color', '#A8E61D'),
    COALESCE(NEW.raw_user_meta_data->>'avatar_pants_color', '#709AD1'),
    COALESCE((NEW.raw_user_meta_data->>'avatar_is_biaude_white')::boolean, false),
    COALESCE(NEW.raw_user_meta_data->>'avatar_equipped_skin', 'none'),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    bucque = COALESCE(EXCLUDED.bucque, public.profiles.bucque, ''),
    fams = EXCLUDED.fams,
    tabagns = EXCLUDED.tabagns,
    proms = EXCLUDED.proms,
    brousoufs = COALESCE(EXCLUDED.brousoufs, public.profiles.brousoufs),
    zloeils = COALESCE(EXCLUDED.zloeils, public.profiles.zloeils),
    avatar_state = COALESCE(EXCLUDED.avatar_state, public.profiles.avatar_state),
    avatar_skin_color = COALESCE(EXCLUDED.avatar_skin_color, public.profiles.avatar_skin_color),
    avatar_hair_color = COALESCE(EXCLUDED.avatar_hair_color, public.profiles.avatar_hair_color),
    avatar_tshirt_color = COALESCE(EXCLUDED.avatar_tshirt_color, public.profiles.avatar_tshirt_color),
    avatar_pants_color = COALESCE(EXCLUDED.avatar_pants_color, public.profiles.avatar_pants_color),
    avatar_is_biaude_white = COALESCE(EXCLUDED.avatar_is_biaude_white, public.profiles.avatar_is_biaude_white),
    avatar_equipped_skin = COALESCE(EXCLUDED.avatar_equipped_skin, public.profiles.avatar_equipped_skin, 'none'),
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
