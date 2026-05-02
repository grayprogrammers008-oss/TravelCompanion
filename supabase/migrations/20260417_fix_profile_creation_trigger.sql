-- Fix: Create profile auto-creation trigger for new auth users
-- The signup flow relies on this trigger to create profiles table entries.

-- Function to create a profile row when a new auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log the error but don't block auth user creation
  RAISE WARNING 'handle_new_user failed: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- Drop trigger if it already exists (idempotent)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger that fires after a new auth user is inserted
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;
