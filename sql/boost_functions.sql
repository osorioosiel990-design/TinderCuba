-- Función para activar el Boost Semanal (suma 7 días respetando el tiempo restante si ya lo tenía)
CREATE OR REPLACE FUNCTION give_weekly_boost(p_user_id UUID) 
RETURNS VOID AS $$
BEGIN
  UPDATE profiles 
  SET boost_until = GREATEST(COALESCE(boost_until, now()), now()) + interval '7 days'
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Función para activar o extender la Membresía VIP por 30 días
CREATE OR REPLACE FUNCTION give_vip_subscription(p_user_id UUID) 
RETURNS VOID AS $$
BEGIN
  UPDATE profiles 
  SET is_premium = true,
      premium_expires_at = GREATEST(COALESCE(premium_expires_at, now()), now()) + interval '30 days'
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;
