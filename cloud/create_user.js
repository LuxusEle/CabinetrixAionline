const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function createUser() {
  const email = 'asanke1@gmail.com';
  const password = '123456';

  console.log(`Creating user ${email} in Supabase (${SUPABASE_URL})...`);
  
  const { data, error } = await supabase.auth.signUp({
    email: email,
    password: password
  });

  if (error) {
    console.error('Error creating user:', error.message);
  } else {
    console.log('✅ User registered successfully in Supabase!');
    console.log('User ID:', data.user ? data.user.id : 'Pending Confirmation');
    console.log('Email:', email);
    console.log('Password:', password);
  }
}

createUser();
