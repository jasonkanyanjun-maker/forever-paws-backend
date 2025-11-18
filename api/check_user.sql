-- Check if user exists in public.users table
SELECT id, email, username, display_name, created_at 
FROM public.users 
WHERE email = 'jason.kanyanjun@gmail.com';

-- Check if user exists in auth.users table
SELECT id, email, created_at, email_confirmed_at, last_sign_in_at
FROM auth.users 
WHERE email = 'jason.kanyanjun@gmail.com';