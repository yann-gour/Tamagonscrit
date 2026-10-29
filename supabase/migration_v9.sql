-- Migration v9 : Ajout des monnaies (brousoufs et zloeils) et sécurisation des contraintes bucque

-- 1. Ajout de la colonne brousoufs et zloeils dans public.profiles, et définition par défaut pour bucque
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS brousoufs integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS zloeils integer DEFAULT 0,
  ALTER COLUMN bucque SET DEFAULT '';

-- 2. Ajout de la colonne brousoufs dans public.conscrit_state
ALTER TABLE public.conscrit_state
  ADD COLUMN IF NOT EXISTS brousoufs integer DEFAULT 0;

-- 3. Mise à jour de la fonction trigger handle_user_profile_update pour prendre en compte brousoufs et zloeils
CREATE OR REPLACE FUNCTION public.handle_user_profile_update()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, bucque, fams, tabagns, proms,
    brousoufs, zloeils,
    avatar_state, avatar_skin_color, avatar_hair_color,
    avatar_tshirt_color, avatar_pants_color, avatar_is_biaude_white, updated_at
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
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
