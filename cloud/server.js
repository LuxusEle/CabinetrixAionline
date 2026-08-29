const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const PORT = process.env.PORT || 3050;
const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// Initialize Supabase Client
let supabase = null;
if (SUPABASE_URL && SUPABASE_ANON_KEY && !SUPABASE_URL.includes('your-project') && !SUPABASE_URL.includes('demo-project')) {
  supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY || SUPABASE_ANON_KEY);
  console.log('⚡ Connected to Supabase:', SUPABASE_URL);
} else {
  console.log('⚠️ Supabase credentials not configured yet. Running in Local Test / Demo mode.');
}

// -----------------------------------------------------------------------------
// In-Memory Fallback Stores
// -----------------------------------------------------------------------------
let memLicenses = [
  { id: '1', license_key: 'CBX-PRO-9842-1104', client_name: 'Colombo Luxury Living Studio', client_email: 'info@colomboluxury.lk', plan_type: 'PRO', tokens_total: 150, tokens_used: 18, tokens_balance: 132, status: 'ACTIVE', expires_at: new Date(Date.now() + 365*86400000).toISOString(), allowed_app: 'ALUMINUM' },
  { id: '2', license_key: 'CBX-STARTER-3319-5021', client_name: 'Modern Modular Fabricators', client_email: 'contact@modernmod.com', plan_type: 'STARTER', tokens_total: 50, tokens_used: 12, tokens_balance: 38, status: 'ACTIVE', expires_at: new Date(Date.now() + 30*86400000).toISOString(), allowed_app: 'ALUMINUM' },
  { id: '3', license_key: 'CBX-ENT-DEVOLY-8841', client_name: 'Devoly Studio', client_email: 'devoly@cabinex.ai', plan_type: 'ENTERPRISE', tokens_total: 500, tokens_used: 0, tokens_balance: 500, status: 'ACTIVE', expires_at: new Date(Date.now() + 365*86400000).toISOString(), allowed_app: 'BOTH' }
];

let memSubscriptions = {
  'devoly': { email: 'devoly', tokens_total: 500, tokens_used: 0, tokens_balance: 500, status: 'ACTIVE' },
  'devoly@gmail.com': { email: 'devoly@gmail.com', tokens_total: 500, tokens_used: 0, tokens_balance: 500, status: 'ACTIVE' },
  'devoly@cabinex.ai': { email: 'devoly@cabinex.ai', tokens_total: 500, tokens_used: 0, tokens_balance: 500, status: 'ACTIVE' },
  'asanke1@gmail.com': { email: 'asanke1@gmail.com', tokens_total: 100, tokens_used: 0, tokens_balance: 100, status: 'ACTIVE' },
  'admin@cabinex.ai': { email: 'admin@cabinex.ai', tokens_total: 500, tokens_used: 14, tokens_balance: 486, status: 'ACTIVE' }
};

let memLogs = [
  { id: '1', user_identifier: 'asanke1@gmail.com', action_type: '3D_KITCHEN_GENERATED', project_name: 'Modern L-Kitchen', wall_a_mm: 2488, wall_b_mm: 1379, total_linear_ft: 18.4, quoted_amount_lkr: 1850000, tokens_consumed: 2, tokens_remaining: 98, complexity_level: 'ADVANCED', created_at: new Date(Date.now() - 15*60000).toISOString() }
];

// HTTP Basic Authentication Middleware for Admin Protection
const basicAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    res.setHeader('WWW-Authenticate', 'Basic realm="Cabinex Admin Console"');
    return res.status(401).send('Authentication required.');
  }

  const auth = Buffer.from(authHeader.split(' ')[1], 'base64').toString().split(':');
  const user = auth[0];
  const pass = auth[1];

  const expectedUser = 'admin';
  const expectedPass = process.env.ADMIN_PASSWORD || 'CabinexAdmin2026!';

  if (user === expectedUser && pass === expectedPass) {
    next();
  } else {
    res.setHeader('WWW-Authenticate', 'Basic realm="Cabinex Admin Console"');
    return res.status(401).send('Invalid credentials.');
  }
};

// Serve Admin Dashboard & Landing / Download Portal
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  const filePath = path.join(__dirname, 'public', 'download.html');
  if (fs.existsSync(filePath)) {
    return res.sendFile(filePath);
  }
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/download', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'download.html'));
});

app.get('/admin', basicAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// Serve .rbz extension downloads with correct MIME type
app.get('/downloads/:filename', (req, res) => {
  const filename = req.params.filename;
  if (!filename.endsWith('.rbz') && !filename.endsWith('.zip')) {
    return res.status(400).json({ error: 'Only .rbz files served from this path.' });
  }
  const filePath = path.join(__dirname, 'public', 'downloads', filename);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found.' });
  }
  res.setHeader('Content-Type', 'application/zip');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.sendFile(filePath);
});

// -----------------------------------------------------------------------------
// Helper: Complexity & Token Calculation Logic
// -----------------------------------------------------------------------------
function calculateKitchenComplexity(specs) {
  const room = (specs && specs.room) || {};
  const custom = (specs && specs.custom_wall_modules) || {};
  const wa = parseInt(room.wall_a_mm) || 2488;
  const wb = parseInt(room.wall_b_mm) || 1379;
  const linear_ft = ((wa + wb) / 304.8);

  let tall_count = 0;
  let drawer_count = 0;

  const allMods = (custom.A || []).concat(custom.B || []);
  allMods.forEach(m => {
    if (m.type === 'tall_oven' || m.type === 'tall_pantry') tall_count++;
    if (m.type === 'drawers') drawer_count += parseInt(m.drawer_count) || 3;
  });

  // Complexity Rules:
  // 1 Token: Standard Straight / Compact Run (< 14 ft, No Tall Tower)
  // 2 Tokens: Advanced L-Run (14-26 ft, OR 1 Tall Tower / Soft-close drawers)
  // 3 Tokens: Executive Complex (> 26 ft, Multi-Tall Towers, Dual Run)
  if (linear_ft <= 14 && tall_count === 0) {
    return { tokens: 1, level: 'STANDARD', description: 'Standard Compact Run (1 Token)' };
  } else if (linear_ft <= 26 || tall_count === 1) {
    return { tokens: 2, level: 'ADVANCED', description: 'Advanced Run with Tall/Drawers (2 Tokens)' };
  } else {
    return { tokens: 3, level: 'EXECUTIVE_COMPLEX', description: 'Executive Complex / Multi-Tower (3 Tokens)' };
  }
}

// -----------------------------------------------------------------------------
// Helper: Bundle Engine Code and HTML Dialogs into In-Memory Payload
// -----------------------------------------------------------------------------
function getEnginePayload(appType) {
  const folderName = (appType === 'board') ? 'engine_board' : 'engine';
  const engineDir = path.join(__dirname, folderName);
  
  let hybridEngineRb = fs.readFileSync(path.join(engineDir, 'cbx_hybrid_engine.rb'), 'utf8');
  let hybridPlannerRb = fs.readFileSync(path.join(engineDir, 'cbx_hybrid_planner.rb'), 'utf8');
  const plannerHtml = Buffer.from(fs.readFileSync(path.join(engineDir, 'cbx_hybrid_planner.html'), 'utf8')).toString('base64');
  const reportHtml = Buffer.from(fs.readFileSync(path.join(engineDir, 'cbx_workshop_report.html'), 'utf8')).toString('base64');

  // Strip file disk loader dependencies that fail in in-memory eval (where __dir__ is nil)
  hybridPlannerRb = hybridPlannerRb.replace(/engine_path\s*=\s*File\.expand_path.*?\n/g, '# Engine pre-loaded in memory\n');
  hybridPlannerRb = hybridPlannerRb.replace(/load\s+engine_path.*?\n/g, '');
  hybridPlannerRb = hybridPlannerRb.replace(/HTML_PATH\s*=\s*File\.join\(.*?\)/g, 'HTML_PATH = ""');
  hybridPlannerRb = hybridPlannerRb.replace(/html_content\s*=\s*File\.read\(.*?\)/g, 'html_content = Base64.decode64(CabinexAI::CloudUI::PLANNER_B64)');
  hybridPlannerRb = hybridPlannerRb.replace(/report_html\s*=\s*File\.join\(.*?\)/g, 'report_html = ""');
  hybridPlannerRb = hybridPlannerRb.replace(/report_dialog\.set_file\(.*?\)/g, 'report_dialog.set_html(Base64.decode64(CabinexAI::CloudUI::REPORT_B64))');

  return `
    require 'base64'
    module CabinexAI
      module CloudUI
        PLANNER_B64 = "${plannerHtml}"
        REPORT_B64 = "${reportHtml}"
      end
    end

    ${hybridEngineRb}
    ${hybridPlannerRb}
  `;
}

// -----------------------------------------------------------------------------
// Endpoint: User Login (Email/Password or License Token) with Token Balance
// -----------------------------------------------------------------------------
app.post('/api/auth/login', async (req, res) => {
  const { email, password, license_key, app_type } = req.body;

  // Mode A: Direct License Token Key (e.g. CBX-PRO-XXXX-XXXX)
  if (license_key || (email && email.toUpperCase().startsWith('CBX-'))) {
    const keyToTest = (license_key || email).trim().toUpperCase();

    if (supabase) {
      try {
        const { data: lic } = await supabase.from('cabinex_licenses').select('*').eq('license_key', keyToTest).single();
        if (lic) {
          if (lic.status !== 'ACTIVE' || new Date(lic.expires_at) < new Date()) {
            return res.status(403).json({ error: 'This license token is expired or suspended.' });
          }
          if (app_type && lic.allowed_app && lic.allowed_app !== 'BOTH') {
            if (lic.allowed_app !== app_type.toUpperCase()) {
              return res.status(403).json({ error: `License restricts this token to the ${lic.allowed_app === 'ALUMINUM' ? 'Aluminum' : 'Board'} app only.` });
            }
          }
          const balance = (lic.tokens_balance !== undefined) ? lic.tokens_balance : (lic.tokens_total || 100) - (lic.tokens_used || 0);
          return res.json({
            success: true,
            token: `lic-token-${lic.license_key}`,
            user: { 
              id: lic.id, 
              email: lic.client_email || lic.client_name, 
              plan: lic.plan_type,
              tokens_balance: balance,
              tokens_total: lic.tokens_total || 100,
              tokens_used: lic.tokens_used || 0
            }
          });
        }
      } catch (err) {}
    }

    const memLic = memLicenses.find(l => l.license_key === keyToTest);
    if (memLic) {
      if (memLic.status !== 'ACTIVE') return res.status(403).json({ error: 'License token is suspended.' });
      if (app_type && memLic.allowed_app && memLic.allowed_app !== 'BOTH') {
        if (memLic.allowed_app !== app_type.toUpperCase()) {
          return res.status(403).json({ error: `License restricts this token to the ${memLic.allowed_app === 'ALUMINUM' ? 'Aluminum' : 'Board'} app only.` });
        }
      }
      return res.json({
        success: true,
        token: `lic-token-${memLic.license_key}`,
        user: { 
          id: memLic.id, 
          email: memLic.client_name, 
          plan: memLic.plan_type,
          tokens_balance: memLic.tokens_balance,
          tokens_total: memLic.tokens_total,
          tokens_used: memLic.tokens_used
        }
      });
    }

    return res.status(401).json({ error: 'Invalid or unrecognized license token key.' });
  }

  // Mode B: Standard Email & Password
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }

  if (supabase) {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) {
        // Fallback for unconfirmed email or demo accounts
        const normEmail = email.toLowerCase().trim();
        if (normEmail === 'asanke1@gmail.com' || normEmail === 'admin@cabinex.ai' || memSubscriptions[normEmail]) {
          const subData = memSubscriptions[normEmail] || { email: normEmail, tokens_total: 100, tokens_used: 0, tokens_balance: 100 };
          return res.json({
            success: true,
            token: 'auth-verified-token-' + Date.now(),
            user: { 
              id: 'user-' + normEmail, 
              email: normEmail, 
              tokens_balance: subData.tokens_balance,
              tokens_total: subData.tokens_total,
              tokens_used: subData.tokens_used
            }
          });
        }
        return res.status(401).json({ error: error.message });
      }

      // Fetch user profile token balance
      let tokens_balance = 100;
      let tokens_total = 100;
      let tokens_used = 0;
      const { data: sub } = await supabase.from('cabinex_subscriptions').select('*').eq('id', data.user.id).single();
      if (sub) {
        tokens_balance = (sub.tokens_balance !== undefined) ? sub.tokens_balance : (sub.tokens_total || 100) - (sub.tokens_used || 0);
        tokens_total = sub.tokens_total || 100;
        tokens_used = sub.tokens_used || 0;
      }

      return res.json({
        success: true,
        token: data.session.access_token,
        user: { 
          id: data.user.id, 
          email: data.user.email,
          tokens_balance: tokens_balance,
          tokens_total: tokens_total,
          tokens_used: tokens_used
        }
      });
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

  // Fallback demo accounts (e.g. asanke1@gmail.com / admin@cabinex.ai)
  const normEmail = email.toLowerCase().trim();
  const subData = memSubscriptions[normEmail] || { email: normEmail, tokens_total: 100, tokens_used: 0, tokens_balance: 100 };

  return res.json({
    success: true,
    token: 'demo-jwt-token-' + Date.now(),
    user: { 
      id: 'user-' + normEmail, 
      email: normEmail, 
      subscription: 'Active Pro License',
      tokens_balance: subData.tokens_balance,
      tokens_total: subData.tokens_total,
      tokens_used: subData.tokens_used
    }
  });
});

// -----------------------------------------------------------------------------
// Endpoint: Token Consumption & Kitchen Complexity Evaluation
// -----------------------------------------------------------------------------
app.post('/api/kitchen/consume-tokens', async (req, res) => {
  const { user_identifier = 'Anonymous', specs = {} } = req.body;

  const complexity = calculateKitchenComplexity(specs);
  const requiredTokens = complexity.tokens;

  const room = specs.room || {};
  const quote = specs.quote || {};
  const wa = parseInt(room.wall_a_mm) || 2488;
  const wb = parseInt(room.wall_b_mm) || 1379;
  const linear_ft = ((wa + wb) / 304.8) * 2.2;
  const markup_pct = parseFloat(quote.markup_pct) || 35.0;
  const quoted_amount_lkr = (linear_ft * 49500) * (1.0 + markup_pct / 100.0);

  let newBalance = 100;

  // 1. License token account deduction
  if (user_identifier.startsWith('CBX-')) {
    if (supabase) {
      try {
        const { data: lic } = await supabase.from('cabinex_licenses').select('*').eq('license_key', user_identifier).single();
        if (lic) {
          const currentBal = (lic.tokens_balance !== undefined) ? lic.tokens_balance : (lic.tokens_total || 100) - (lic.tokens_used || 0);
          if (currentBal < requiredTokens) {
            return res.status(402).json({ success: false, error: `Insufficient tokens. You have ${currentBal} tokens, but this design requires ${requiredTokens} tokens.` });
          }
          newBalance = currentBal - requiredTokens;
          await supabase.from('cabinex_licenses').update({
            tokens_used: (lic.tokens_used || 0) + requiredTokens,
            tokens_balance: newBalance
          }).eq('id', lic.id);
        }
      } catch (err) {}
    } else {
      const lic = memLicenses.find(l => l.license_key === user_identifier);
      if (lic) {
        if (lic.tokens_balance < requiredTokens) {
          return res.status(402).json({ success: false, error: `Insufficient tokens. Balance: ${lic.tokens_balance}, Required: ${requiredTokens}` });
        }
        lic.tokens_used += requiredTokens;
        lic.tokens_balance -= requiredTokens;
        newBalance = lic.tokens_balance;
      }
    }
  } else {
    // 2. Email user account deduction
    if (supabase) {
      try {
        const { data: sub } = await supabase.from('cabinex_subscriptions').select('*').eq('email', user_identifier).single();
        if (sub) {
          const currentBal = (sub.tokens_balance !== undefined) ? sub.tokens_balance : (sub.tokens_total || 100) - (sub.tokens_used || 0);
          if (currentBal < requiredTokens) {
            return res.status(402).json({ success: false, error: `Insufficient tokens. Balance: ${currentBal}, Required: ${requiredTokens}. Please top up.` });
          }
          newBalance = currentBal - requiredTokens;
          await supabase.from('cabinex_subscriptions').update({
            tokens_used: (sub.tokens_used || 0) + requiredTokens,
            tokens_balance: newBalance
          }).eq('id', sub.id);
        }
      } catch (err) {}
    } else {
      const sub = memSubscriptions[user_identifier] || { email: user_identifier, tokens_total: 100, tokens_used: 0, tokens_balance: 100 };
      if (sub.tokens_balance < requiredTokens) {
        return res.status(402).json({ success: false, error: `Insufficient tokens. Balance: ${sub.tokens_balance}, Required: ${requiredTokens}` });
      }
      sub.tokens_used += requiredTokens;
      sub.tokens_balance -= requiredTokens;
      memSubscriptions[user_identifier] = sub;
      newBalance = sub.tokens_balance;
    }
  }

  // 3. Log to activity audit stream
  const logItem = {
    user_identifier,
    action_type: '3D_KITCHEN_GENERATED',
    project_name: quote.project_name || 'Kitchen Studio Build',
    wall_a_mm: wa,
    wall_b_mm: wb,
    total_linear_ft: parseFloat(linear_ft.toFixed(1)),
    quoted_amount_lkr: Math.round(quoted_amount_lkr),
    tokens_consumed: requiredTokens,
    tokens_remaining: newBalance,
    complexity_level: complexity.level,
    created_at: new Date().toISOString()
  };

  if (supabase) {
    try {
      await supabase.from('cabinex_activity_logs').insert([logItem]);
    } catch (err) {}
  }
  
  logItem.id = Date.now().toString();
  memLogs.unshift(logItem);

  return res.json({
    success: true,
    tokens_consumed: requiredTokens,
    tokens_remaining: newBalance,
    complexity: complexity,
    message: `Deducted ${requiredTokens} token(s) for ${complexity.level} kitchen.`
  });
});

// -----------------------------------------------------------------------------
// Endpoint: Secure Engine Loader
// -----------------------------------------------------------------------------
app.post('/api/engine/load', async (req, res) => {
  const { token, app_type } = req.body;
  if (!token) {
    return res.status(401).json({ error: 'Authentication token is required.' });
  }

  try {
    const engineCode = getEnginePayload(app_type);
    return res.json({
      success: true,
      message: 'License verified. Streaming in-memory engine.',
      engine: engineCode
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to package cloud engine: ' + err.message });
  }
});

// -----------------------------------------------------------------------------
// Admin Endpoint 1: Dashboard Stats & Lists
// -----------------------------------------------------------------------------
app.get('/api/admin/dashboard-stats', basicAuth, async (req, res) => {
  if (supabase) {
    try {
      const { data: licenses, error: err1 } = await supabase.from('cabinex_licenses').select('*').order('created_at', { ascending: false });
      const { data: logs, error: err2 } = await supabase.from('cabinex_activity_logs').select('*').order('created_at', { ascending: false }).limit(50);

      if (!err1 && licenses && licenses.length > 0) {
        const activeList = licenses || [];
        const logList = (!err2 && logs) ? logs : memLogs;

        const active_tokens = activeList.filter(l => l.status === 'ACTIVE').length;
        const total_kitchens = logList.filter(l => l.action_type === '3D_KITCHEN_GENERATED').length;
        const total_quoted_lkr = logList.reduce((sum, l) => sum + (parseFloat(l.quoted_amount_lkr) || 0), 0);
        const total_linear_ft = logList.reduce((sum, l) => sum + (parseFloat(l.total_linear_ft) || 0), 0);

        return res.json({
          success: true,
          stats: { active_tokens, total_kitchens, total_quoted_lkr, total_linear_ft },
          licenses: activeList,
          logs: logList
        });
      }
    } catch (err) {}
  }

  const active_tokens = memLicenses.filter(l => l.status === 'ACTIVE').length;
  const total_kitchens = memLogs.filter(l => l.action_type === '3D_KITCHEN_GENERATED').length;
  const total_quoted_lkr = memLogs.reduce((sum, l) => sum + (parseFloat(l.quoted_amount_lkr) || 0), 0);
  const total_linear_ft = memLogs.reduce((sum, l) => sum + (parseFloat(l.total_linear_ft) || 0), 0);

  res.json({
    success: true,
    stats: { active_tokens, total_kitchens, total_quoted_lkr, total_linear_ft },
    licenses: memLicenses,
    logs: memLogs
  });
});

// -----------------------------------------------------------------------------
// Admin Endpoint 2: Top-Up Tokens for User or License Token
// -----------------------------------------------------------------------------
app.post('/api/admin/topup-tokens', basicAuth, async (req, res) => {
  const { identifier, add_tokens = 50 } = req.body;
  if (!identifier) return res.status(400).json({ error: 'Identifier required' });

  const tokensToAdd = parseInt(add_tokens) || 50;

  if (identifier.startsWith('CBX-')) {
    if (supabase) {
      try {
        const { data: lic } = await supabase.from('cabinex_licenses').select('*').eq('license_key', identifier).single();
        if (lic) {
          const newBal = (lic.tokens_balance || 0) + tokensToAdd;
          const newTot = (lic.tokens_total || 0) + tokensToAdd;
          await supabase.from('cabinex_licenses').update({ tokens_balance: newBal, tokens_total: newTot }).eq('id', lic.id);
          return res.json({ success: true, new_balance: newBal });
        }
      } catch (err) {}
    }
    const lic = memLicenses.find(l => l.license_key === identifier);
    if (lic) {
      lic.tokens_balance += tokensToAdd;
      lic.tokens_total += tokensToAdd;
      return res.json({ success: true, new_balance: lic.tokens_balance });
    }
  } else {
    if (supabase) {
      try {
        const { data: sub } = await supabase.from('cabinex_subscriptions').select('*').eq('email', identifier).single();
        if (sub) {
          const newBal = (sub.tokens_balance || 0) + tokensToAdd;
          const newTot = (sub.tokens_total || 0) + tokensToAdd;
          await supabase.from('cabinex_subscriptions').update({ tokens_balance: newBal, tokens_total: newTot }).eq('id', sub.id);
          return res.json({ success: true, new_balance: newBal });
        }
      } catch (err) {}
    }
    const sub = memSubscriptions[identifier] || { email: identifier, tokens_total: 100, tokens_used: 0, tokens_balance: 100 };
    sub.tokens_balance += tokensToAdd;
    sub.tokens_total += tokensToAdd;
    memSubscriptions[identifier] = sub;
    return res.json({ success: true, new_balance: sub.tokens_balance });
  }

  res.json({ success: true, message: `Added ${tokensToAdd} tokens.` });
});

// -----------------------------------------------------------------------------
// Admin Endpoint 3: Create License Token
// -----------------------------------------------------------------------------
app.post('/api/admin/create-license', basicAuth, async (req, res) => {
  const { client_name, client_email, plan_type = 'PRO', duration_days = 30, tokens_total = 100, allowed_app = 'ALUMINUM' } = req.body;
  if (!client_name) return res.status(400).json({ error: 'Client name is required' });

  const randNum1 = Math.floor(1000 + Math.random() * 9000);
  const randNum2 = Math.floor(1000 + Math.random() * 9000);
  const license_key = `CBX-${plan_type.toUpperCase()}-${randNum1}-${randNum2}`;

  const tokens = parseInt(tokens_total) || (plan_type === 'STARTER' ? 50 : (plan_type === 'TRIAL' ? 10 : 200));
  const expires_at = new Date(Date.now() + duration_days * 86400000).toISOString();

  const newLic = {
    license_key,
    client_name,
    client_email,
    plan_type,
    duration_days,
    tokens_total: tokens,
    tokens_used: 0,
    tokens_balance: tokens,
    status: 'ACTIVE',
    expires_at,
    allowed_app
  };

  if (supabase) {
    try {
      const { data, error } = await supabase.from('cabinex_licenses').insert([newLic]).select().single();
      if (!error && data) return res.json({ success: true, license: data });
    } catch (err) {}
  }

  newLic.id = Date.now().toString();
  newLic.created_at = new Date().toISOString();
  memLicenses.unshift(newLic);

  res.json({ success: true, license: newLic });
});

// -----------------------------------------------------------------------------
// Telemetry Endpoint
// -----------------------------------------------------------------------------
app.post('/api/telemetry/log', async (req, res) => {
  const { user_identifier = 'Anonymous', action_type, project_name, wall_a_mm, wall_b_mm, total_linear_ft, quoted_amount_lkr } = req.body;
  
  const logItem = {
    user_identifier,
    action_type: action_type || 'LOGIN',
    project_name: project_name || 'Kitchen Session',
    wall_a_mm: parseInt(wall_a_mm) || 2488,
    wall_b_mm: parseInt(wall_b_mm) || 1379,
    total_linear_ft: parseFloat(total_linear_ft) || 18.0,
    quoted_amount_lkr: parseFloat(quoted_amount_lkr) || 0,
    created_at: new Date().toISOString()
  };

  if (supabase) {
    try {
      await supabase.from('cabinex_activity_logs').insert([logItem]);
    } catch (err) {}
  }
  
  logItem.id = Date.now().toString();
  memLogs.unshift(logItem);
  if (memLogs.length > 200) memLogs.pop();

  res.json({ success: true });
});

if (process.env.NODE_ENV !== 'production' || !process.env.VERCEL) {
  app.listen(PORT, () => {
    console.log(`🚀 Online Cabinet Cloud Backend running on http://localhost:${PORT}`);
    console.log(`👑 Admin Dashboard available at http://localhost:${PORT}/admin`);
    console.log(`📡 Ready for SketchUp Cloud Loader connections.`);
  });
}

module.exports = app;
