-- ============================================
-- Equeue: Smart Queue Management System
-- Database Schema Migration (Supabase PostgreSQL)
-- ============================================

-- ============================================
-- 1. CUSTOM TYPES (ENUMS)
-- ============================================

CREATE TYPE user_role AS ENUM ('user', 'admin', 'super_admin');
CREATE TYPE token_status AS ENUM ('waiting', 'called', 'serving', 'completed', 'cancelled', 'skipped', 'no_show');
CREATE TYPE token_priority AS ENUM ('normal', 'emergency', 'senior', 'pregnant', 'disabled');
CREATE TYPE counter_status AS ENUM ('open', 'closed');
CREATE TYPE notification_type AS ENUM ('queue_update', 'turn_reminder', 'delay', 'completion');

-- ============================================
-- 2. TABLES
-- ============================================

-- Profiles (extends auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    role user_role NOT NULL DEFAULT 'user',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Branches (service centers)
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    contact TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    admin_id UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Services offered at each branch
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    avg_service_time_min INTEGER NOT NULL DEFAULT 10,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Counters / service windows at each branch
CREATE TABLE counters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    status counter_status NOT NULL DEFAULT 'closed',
    current_token_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tokens (core queue entries)
CREATE TABLE tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_number TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    queue_position INTEGER NOT NULL DEFAULT 0,
    status token_status NOT NULL DEFAULT 'waiting',
    priority token_priority NOT NULL DEFAULT 'normal',
    is_walkin BOOLEAN NOT NULL DEFAULT FALSE,
    qr_code TEXT,
    estimated_wait_min INTEGER NOT NULL DEFAULT 0,
    checked_in_at TIMESTAMPTZ,
    called_at TIMESTAMPTZ,
    served_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type notification_type NOT NULL DEFAULT 'queue_update',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- QR Check-ins
CREATE TABLE qr_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES tokens(id) ON DELETE CASCADE,
    check_in_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'checked_in'
);

-- Daily Analytics (aggregated)
CREATE TABLE analytics_daily (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    customers_served INTEGER NOT NULL DEFAULT 0,
    avg_wait_time_min NUMERIC(6,2) NOT NULL DEFAULT 0,
    peak_hour INTEGER,
    completion_rate NUMERIC(5,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (branch_id, date)
);

-- ============================================
-- 3. INDEXES
-- ============================================

CREATE INDEX idx_tokens_user_id ON tokens(user_id);
CREATE INDEX idx_tokens_service_id ON tokens(service_id);
CREATE INDEX idx_tokens_branch_id ON tokens(branch_id);
CREATE INDEX idx_tokens_status ON tokens(status);
CREATE INDEX idx_tokens_created_at ON tokens(created_at DESC);
CREATE INDEX idx_tokens_service_status ON tokens(service_id, status);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX idx_services_branch_id ON services(branch_id);
CREATE INDEX idx_counters_branch_id ON counters(branch_id);
CREATE INDEX idx_analytics_branch_date ON analytics_daily(branch_id, date);

-- ============================================
-- 4. FUNCTIONS
-- ============================================

-- Auto-generate token number: PREFIX-NNN (e.g., A-001, A-002)
CREATE OR REPLACE FUNCTION generate_token_number(p_service_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_prefix TEXT;
    v_count INTEGER;
    v_number TEXT;
BEGIN
    -- Get first letter of service name as prefix
    SELECT UPPER(LEFT(name, 1)) INTO v_prefix
    FROM services WHERE id = p_service_id;
    
    IF v_prefix IS NULL THEN
        v_prefix := 'T';
    END IF;
    
    -- Count tokens for this service today
    SELECT COUNT(*) + 1 INTO v_count
    FROM tokens
    WHERE service_id = p_service_id
      AND created_at::DATE = CURRENT_DATE;
    
    v_number := v_prefix || '-' || LPAD(v_count::TEXT, 3, '0');
    RETURN v_number;
END;
$$ LANGUAGE plpgsql;

-- Calculate estimated wait time for a service
CREATE OR REPLACE FUNCTION calculate_wait_time(p_service_id UUID, p_position INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_avg_time INTEGER;
BEGIN
    SELECT avg_service_time_min INTO v_avg_time
    FROM services WHERE id = p_service_id;
    
    IF v_avg_time IS NULL THEN
        v_avg_time := 10;
    END IF;
    
    RETURN p_position * v_avg_time;
END;
$$ LANGUAGE plpgsql;

-- Get next queue position for a service today
CREATE OR REPLACE FUNCTION get_next_queue_position(p_service_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_position INTEGER;
BEGIN
    SELECT COALESCE(MAX(queue_position), 0) + 1 INTO v_position
    FROM tokens
    WHERE service_id = p_service_id
      AND created_at::DATE = CURRENT_DATE
      AND status IN ('waiting', 'called', 'serving');
    
    RETURN v_position;
END;
$$ LANGUAGE plpgsql;

-- Auto-create profile on auth signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, phone, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        'user'::public.user_role
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. TRIGGERS
-- ============================================

-- Auto-create profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Updated_at triggers
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_branches_updated_at
    BEFORE UPDATE ON branches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_services_updated_at
    BEFORE UPDATE ON services
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_tokens_updated_at
    BEFORE UPDATE ON tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_daily ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
    ON profiles FOR SELECT
    USING (public.is_admin());

-- BRANCHES (public read, admin write)
CREATE POLICY "Anyone can view active branches"
    ON branches FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage branches"
    ON branches FOR ALL
    USING (public.is_admin());

-- SERVICES (public read, admin write)
CREATE POLICY "Anyone can view active services"
    ON services FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Admins can manage services"
    ON services FOR ALL
    USING (public.is_admin());

-- COUNTERS (public read, admin write)
CREATE POLICY "Anyone can view counters"
    ON counters FOR SELECT
    USING (TRUE);

CREATE POLICY "Admins can manage counters"
    ON counters FOR ALL
    USING (public.is_admin());

-- TOKENS
CREATE POLICY "Users can view their own tokens"
    ON tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create tokens"
    ON tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all tokens"
    ON tokens FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can update tokens"
    ON tokens FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "Users can cancel their own tokens"
    ON tokens FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (status = 'cancelled');

-- NOTIFICATIONS
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (TRUE);

-- QR CHECKINS
CREATE POLICY "Users can view their own checkins"
    ON qr_checkins FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM tokens
            WHERE tokens.id = qr_checkins.token_id
              AND tokens.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage checkins"
    ON qr_checkins FOR ALL
    USING (public.is_admin());

-- ANALYTICS
CREATE POLICY "Admins can view analytics"
    ON analytics_daily FOR SELECT
    USING (public.is_admin());

CREATE POLICY "Admins can manage analytics"
    ON analytics_daily FOR ALL
    USING (public.is_admin());

-- ============================================
-- 7. ENABLE REALTIME
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE tokens;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================
-- 8. SEED DATA (Demo)
-- ============================================

-- Note: This seed data uses a placeholder admin UUID.
-- After creating an admin user through the app, update the admin_id in branches.

-- Insert demo branches
INSERT INTO branches (id, name, address, contact, is_active) VALUES
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'City General Hospital', '123 Health Street, Medical District', '+91 98765 43210', TRUE),
    ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Central National Bank', '456 Finance Avenue, Business Park', '+91 98765 43211', TRUE),
    ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'District Passport Office', '789 Government Road, Civil Lines', '+91 98765 43212', TRUE),
    ('d4e5f6a7-b8c9-0123-defa-234567890123', 'Metro Service Center', '101 Auto Lane, Industrial Area', '+91 98765 43213', TRUE);

-- Insert demo services
INSERT INTO services (id, branch_id, name, description, avg_service_time_min, is_active) VALUES
    -- Hospital services
    (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'General Consultation', 'General physician consultation', 15, TRUE),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Lab Tests', 'Blood tests and diagnostics', 10, TRUE),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Pharmacy', 'Prescription medicine pickup', 5, TRUE),
    (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'X-Ray & Imaging', 'X-Ray, CT Scan, MRI', 20, TRUE),
    -- Bank services
    (gen_random_uuid(), 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Account Opening', 'New savings/current account', 25, TRUE),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Cash Deposit', 'Cash and cheque deposit', 8, TRUE),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Loan Enquiry', 'Home, personal, vehicle loans', 20, TRUE),
    -- Passport Office services
    (gen_random_uuid(), 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'New Passport', 'Fresh passport application', 30, TRUE),
    (gen_random_uuid(), 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'Passport Renewal', 'Renewal of existing passport', 20, TRUE),
    (gen_random_uuid(), 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'Document Verification', 'Document verification counter', 15, TRUE),
    -- Vehicle Service Center
    (gen_random_uuid(), 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Regular Service', 'Periodic vehicle service', 45, TRUE),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-0123-defa-234567890123', 'Insurance Claim', 'Vehicle insurance processing', 30, TRUE);
