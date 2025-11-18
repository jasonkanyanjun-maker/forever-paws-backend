-- Enable Row Level Security (RLS) and create policies

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY; -- Products should be publicly readable
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Pets policies
CREATE POLICY "Users can view their own pets" ON pets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own pets" ON pets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pets" ON pets
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own pets" ON pets
    FOR DELETE USING (auth.uid() = user_id);

-- Family members can view pets in their families
CREATE POLICY "Family members can view family pets" ON pets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM family_pets fp
            JOIN family_members fm ON fp.family_id = fm.family_id
            WHERE fp.pet_id = pets.id AND fm.user_id = auth.uid()
        )
    );

-- Letters policies
CREATE POLICY "Users can view their own letters" ON letters
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert letters for their pets" ON letters
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (SELECT 1 FROM pets WHERE id = letters.pet_id AND user_id = auth.uid())
    );

CREATE POLICY "Users can update their own letters" ON letters
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own letters" ON letters
    FOR DELETE USING (auth.uid() = user_id);

-- Family members can view letters for family pets
CREATE POLICY "Family members can view family pet letters" ON letters
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM family_pets fp
            JOIN family_members fm ON fp.family_id = fm.family_id
            WHERE fp.pet_id = letters.pet_id AND fm.user_id = auth.uid()
        )
    );

-- Video generations policies
CREATE POLICY "Users can view their own video generations" ON video_generations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert video generations for their pets" ON video_generations
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (SELECT 1 FROM pets WHERE id = video_generations.pet_id AND user_id = auth.uid())
    );

CREATE POLICY "Users can update their own video generations" ON video_generations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own video generations" ON video_generations
    FOR DELETE USING (auth.uid() = user_id);

-- Families policies
CREATE POLICY "Users can view families they belong to" ON families
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM family_members 
            WHERE family_id = families.id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create families" ON families
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Family owners can update their families" ON families
    FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Family owners can delete their families" ON families
    FOR DELETE USING (auth.uid() = created_by);

-- Family members policies
CREATE POLICY "Users can view family members of their families" ON family_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM family_members fm2 
            WHERE fm2.family_id = family_members.family_id AND fm2.user_id = auth.uid()
        )
    );

CREATE POLICY "Family owners can manage family members" ON family_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM families 
            WHERE id = family_members.family_id AND created_by = auth.uid()
        )
    );

CREATE POLICY "Users can join families" ON family_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave families" ON family_members
    FOR DELETE USING (auth.uid() = user_id);

-- Family pets policies
CREATE POLICY "Family members can view family pets" ON family_pets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM family_members 
            WHERE family_id = family_pets.family_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Family members can add pets to family" ON family_pets
    FOR INSERT WITH CHECK (
        auth.uid() = added_by AND
        EXISTS (
            SELECT 1 FROM family_members 
            WHERE family_id = family_pets.family_id AND user_id = auth.uid()
        ) AND
        EXISTS (
            SELECT 1 FROM pets 
            WHERE id = family_pets.pet_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Pet owners can remove their pets from families" ON family_pets
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM pets 
            WHERE id = family_pets.pet_id AND user_id = auth.uid()
        )
    );

-- Orders policies
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (auth.uid() = user_id);

-- Order items policies
CREATE POLICY "Users can view their own order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE id = order_items.order_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create order items for their orders" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE id = order_items.order_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own order items" ON order_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE id = order_items.order_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete their own order items" ON order_items
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE id = order_items.order_id AND user_id = auth.uid()
        )
    );

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- System can create notifications for users
CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- Grant permissions to anon and authenticated roles
GRANT SELECT ON products TO anon;
GRANT SELECT ON products TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON letters TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON video_generations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON families TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON family_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON family_pets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON order_items TO authenticated;
GRANT SELECT, INSERT, UPDATE ON notifications TO authenticated;