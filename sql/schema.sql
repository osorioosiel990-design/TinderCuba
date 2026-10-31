-- 1. Tablas Base
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  bio TEXT,
  gender TEXT, -- 'male', 'female', 'other'
  looking_for TEXT, -- 'male', 'female', 'all'
  birth_date DATE,
  province TEXT,
  avatar_url TEXT,
  is_premium BOOLEAN DEFAULT false,
  premium_expires_at TIMESTAMP WITH TIME ZONE,
  boost_until TIMESTAMP WITH TIME ZONE,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. Tabla de Swipes (Likes/Dislikes)
CREATE TABLE swipes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  swiper_id UUID REFERENCES profiles(id) NOT NULL,
  swiped_id UUID REFERENCES profiles(id) NOT NULL,
  swipe_type TEXT NOT NULL CHECK (swipe_type IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(swiper_id, swiped_id)
);

-- 3. Tabla de Matches (Generada automáticamente por trigger)
CREATE TABLE matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user1_id UUID REFERENCES profiles(id) NOT NULL,
  user2_id UUID REFERENCES profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(user1_id, user2_id)
);

-- 4. Tabla de Mensajes
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES profiles(id) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 5. Trigger para crear matches automáticamente
CREATE OR REPLACE FUNCTION check_for_match() 
RETURNS TRIGGER AS $$
BEGIN
  -- Si es un 'like', verificamos si la otra persona también dio 'like'
  IF NEW.swipe_type = 'like' AND EXISTS (
    SELECT 1 FROM swipes 
    WHERE swiper_id = NEW.swiped_id 
    AND swiped_id = NEW.swiper_id 
    AND swipe_type = 'like'
  ) THEN
    -- Crear el match (asegurando orden de IDs para evitar duplicados por permutación)
    INSERT INTO matches (user1_id, user2_id)
    VALUES (
      LEAST(NEW.swiper_id, NEW.swiped_id),
      GREATEST(NEW.swiper_id, NEW.swiped_id)
    ) ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_swipe_created
AFTER INSERT ON swipes
FOR EACH ROW EXECUTE FUNCTION check_for_match();

-- 6. Políticas de RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Perfiles: Todos pueden ver perfiles, solo el dueño edita
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Swipes: Solo el dueño ve y crea sus swipes
CREATE POLICY "Users can see own swipes" ON swipes FOR SELECT USING (auth.uid() = swiper_id);
CREATE POLICY "Users can create swipes" ON swipes FOR INSERT WITH CHECK (auth.uid() = swiper_id);

-- Matches: Solo los involucrados ven sus matches
CREATE POLICY "Users can see their matches" ON matches FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Mensajes: Solo los miembros del match ven y crean mensajes
CREATE POLICY "Users can see messages in their matches" ON messages FOR SELECT 
USING (EXISTS (SELECT 1 FROM matches WHERE id = match_id AND (user1_id = auth.uid() OR user2_id = auth.uid())));

CREATE POLICY "Users can send messages to their matches" ON messages FOR INSERT 
WITH CHECK (auth.uid() = sender_id AND EXISTS (SELECT 1 FROM matches WHERE id = match_id AND (user1_id = auth.uid() OR user2_id = auth.uid())));
