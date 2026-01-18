-- ============================================
-- Max's Puzzles - Initial Database Schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- FAMILIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS families (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- USERS TABLE (Parents and Children)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  auth_id UUID UNIQUE, -- Links to Supabase auth.users for parents
  email VARCHAR(255) UNIQUE,
  display_name VARCHAR(50) NOT NULL,
  role VARCHAR(10) NOT NULL CHECK (role IN ('parent', 'child')),
  coins INTEGER DEFAULT 0 CHECK (coins >= 0),
  pin_hash VARCHAR(255), -- For children only, hashed 4-digit PIN
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for family lookups
CREATE INDEX IF NOT EXISTS idx_users_family_id ON users(family_id);
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);

-- ============================================
-- MODULE PROGRESS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS module_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_id VARCHAR(50) NOT NULL,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, module_id)
);

-- Index for user progress lookups
CREATE INDEX IF NOT EXISTS idx_module_progress_user ON module_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_module_progress_module ON module_progress(module_id);

-- ============================================
-- ACTIVITY LOG TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  module_id VARCHAR(50) NOT NULL,
  session_start TIMESTAMPTZ DEFAULT NOW(),
  session_end TIMESTAMPTZ,
  duration_seconds INTEGER DEFAULT 0,
  games_played INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  mistakes INTEGER DEFAULT 0,
  coins_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for activity lookups
CREATE INDEX IF NOT EXISTS idx_activity_log_user ON activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_date ON activity_log(session_start);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Families: Users can read their own family
DROP POLICY IF EXISTS "Users can view own family" ON families;
CREATE POLICY "Users can view own family"
  ON families FOR SELECT
  USING (
    id IN (
      SELECT family_id FROM users WHERE auth_id = auth.uid()
    )
  );

-- Families: Users can insert their own family (during signup)
DROP POLICY IF EXISTS "Users can insert own family" ON families;
CREATE POLICY "Users can insert own family"
  ON families FOR INSERT
  WITH CHECK (true);

-- Users: Can read self and family members
DROP POLICY IF EXISTS "Users can view self and family members" ON users;
CREATE POLICY "Users can view self and family members"
  ON users FOR SELECT
  USING (
    auth_id = auth.uid()
    OR
    family_id IN (
      SELECT family_id FROM users WHERE auth_id = auth.uid()
    )
  );

-- Users: Can insert (for adding children)
DROP POLICY IF EXISTS "Users can insert family members" ON users;
CREATE POLICY "Users can insert family members"
  ON users FOR INSERT
  WITH CHECK (
    -- Allow inserting children into user's own family
    family_id IN (
      SELECT family_id FROM users WHERE auth_id = auth.uid() AND role = 'parent'
    )
    OR
    -- Allow the signup trigger to create the initial user
    auth_id = auth.uid()
  );

-- Users: Parents can update children in their family
DROP POLICY IF EXISTS "Parents can update family children" ON users;
CREATE POLICY "Parents can update family children"
  ON users FOR UPDATE
  USING (
    auth_id = auth.uid()
    OR (
      role = 'child' AND
      family_id IN (
        SELECT family_id FROM users WHERE auth_id = auth.uid() AND role = 'parent'
      )
    )
  );

-- Module Progress: Users can read/write their own or children's
DROP POLICY IF EXISTS "Users can manage own progress" ON module_progress;
CREATE POLICY "Users can manage own progress"
  ON module_progress FOR ALL
  USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
    OR
    user_id IN (
      SELECT id FROM users
      WHERE family_id IN (
        SELECT family_id FROM users WHERE auth_id = auth.uid() AND role = 'parent'
      )
    )
  );

-- Activity Log: Same as module progress
DROP POLICY IF EXISTS "Users can manage own activity" ON activity_log;
CREATE POLICY "Users can manage own activity"
  ON activity_log FOR ALL
  USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
    OR
    user_id IN (
      SELECT id FROM users
      WHERE family_id IN (
        SELECT family_id FROM users WHERE auth_id = auth.uid() AND role = 'parent'
      )
    )
  );

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS users_updated_at ON users;
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS module_progress_updated_at ON module_progress;
CREATE TRIGGER module_progress_updated_at
  BEFORE UPDATE ON module_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to add coins (atomic update)
CREATE OR REPLACE FUNCTION add_coins(p_user_id UUID, p_amount INTEGER)
RETURNS INTEGER AS $$
DECLARE
  new_coins INTEGER;
BEGIN
  UPDATE users
  SET coins = GREATEST(0, coins + p_amount)
  WHERE id = p_user_id
  RETURNING coins INTO new_coins;

  RETURN COALESCE(new_coins, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create family and parent user on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_family_id UUID;
  display_name_val TEXT;
BEGIN
  -- Get display name from metadata or use email prefix
  display_name_val := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    split_part(NEW.email, '@', 1)
  );

  -- Create a new family for the user
  INSERT INTO families (name)
  VALUES (display_name_val || '''s Family')
  RETURNING id INTO new_family_id;

  -- Create the parent user record
  INSERT INTO users (auth_id, family_id, email, display_name, role)
  VALUES (
    NEW.id,
    new_family_id,
    NEW.email,
    display_name_val,
    'parent'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert (only create if doesn't exist)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE families IS 'Family units containing parents and children';
COMMENT ON TABLE users IS 'All users - parents authenticate via Supabase auth, children use PIN';
COMMENT ON TABLE module_progress IS 'Game progress data stored as JSONB for flexibility';
COMMENT ON TABLE activity_log IS 'Session tracking for parent dashboard';
COMMENT ON FUNCTION add_coins IS 'Atomic coin update that ensures balance never goes negative';
COMMENT ON FUNCTION handle_new_user IS 'Creates family and user record when parent signs up';
