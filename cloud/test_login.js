const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

async function testLogin() {
  const { data, error } = await supabase.auth.signInWithPassword({
    email: 'asanke1@gmail.com',
    password: '123456'
  });

  if (error) {
    console.log('Login Result: Error -', error.message);
  } else {
    console.log('Login Result: SUCCESS! Token generated:', data.session.access_token.substring(0, 30) + '...');
  }
}

testLogin();
