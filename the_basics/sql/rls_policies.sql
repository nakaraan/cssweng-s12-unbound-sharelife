-- RLS Policies for members table
-- 
-- These policies ensure that:
-- 1. Only authenticated users can insert records
-- 2. Users can only read/update their own records (based on email matching auth.email())
-- 3. The database maintains data integrity

-- Enable RLS on members table
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow authenticated users to insert their own member record
-- This allows the insert after email confirmation
CREATE POLICY "Users can insert member record after auth" ON public.members
  FOR INSERT 
  WITH CHECK (
    auth.role() = 'authenticated' AND 
    email_address = auth.email()
  );

-- Policy 2: Allow users to read their own member record
CREATE POLICY "Users can read own member record" ON public.members
  FOR SELECT 
  USING (
    auth.role() = 'authenticated' AND 
    email_address = auth.email()
  );

-- Policy 3: Allow users to update their own member record
CREATE POLICY "Users can update own member record" ON public.members
  FOR UPDATE 
  USING (
    auth.role() = 'authenticated' AND 
    email_address = auth.email()
  );

-- Policy 4: Allow service role full access (for admin operations)
CREATE POLICY "Service role has full access" ON public.members
  FOR ALL 
  USING (auth.role() = 'service_role');

-- Optional: Policy for admin users to read all members
-- Uncomment if you have an admin role system
-- CREATE POLICY "Admins can read all members" ON public.members
--   FOR SELECT 
--   USING (
--     auth.role() = 'authenticated' AND 
--     EXISTS (
--       SELECT 1 FROM public.members 
--       WHERE email_address = auth.email() 
--       AND status = 'admin'
--     )
--   );