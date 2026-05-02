-- Allow authenticated users to read basic profile info of other users
-- Needed for displaying organizer name/avatar on public trips

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;

-- Allow users to read their own profile
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid());

-- Allow authenticated users to read basic info of any profile
-- (needed for showing organizer names, member avatars, etc.)
CREATE POLICY "profiles_select_others" ON public.profiles
  FOR SELECT TO authenticated
  USING (true);
