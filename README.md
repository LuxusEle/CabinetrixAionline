# CabinetrixAionline

Best-of-the-best curation for the **SketchUp online auth + streaming tool** (the
aluminum builder). Everything here is the superior, working version — no board
leftovers, no dev-dir duplicates.

> **Curated Aug 29, 2026.** All engine/planner code is the **aluminum-pure v5.0.0**
> source (verified: 0 board refs; byte-identical to the deployed cloud payload). The
> `sketchup_ai_integration/` fork was **excluded** — it still contains board/melamine
> code (21 refs).

---

## Layout

```
CabinetrixAionline/
  PDFs/            The 7 reference manuals we read/compared
  analysis/        design/ -> the 10 strategy blueprints (docs/design)
  sketchup/        The aluminum SketchUp extension (canonical source)
  client_plugin/   SketchUp online_cabinet_loader.rb + toolbar icons (auth+stream client)
  cloud/           server.js auth/token/license + engine payload + web public (Vercel)
```

### sketchup/ — the aluminum tool (edit these)
| File | Role |
|------|------|
| `cabinex_ai.rb` | Registrar (entrypoint) |
| `loader.rb` | Extension loader: menu + toolbar + auth flow |
| `cbx_cloud_loader.rb` | Auth + stream the engine from the cloud |
| `cbx_hybrid_engine.rb` | The aluminum engine (BoxBar + ACP + sash + Gola) |
| `cbx_hybrid_planner.rb` / `.html` | 6-step planner UI |
| `cbx_workshop_report.html` | Shop report / per-box pack |
| `cbx_exports.rb` | DXF/CSV/exports |
| `cbx_box_editor.rb` | Per-box editor |
| `cbx_viewport_hud.rb` | Viewport HUD |
| `cbx_ai_assistant.rb` / `cbx_ai_chat.html` | AI Chat |
| `modified_generate_tall_alu_sash_miter_unit.rb` | Tall sash miter unit module |
| `icons/` | 81 toolbar + login assets |

### cloud/ — the auth + streaming server
| File | Role |
|------|------|
| `server.js` | Express: license/token auth, token accounting, `.rbz` download streaming, admin (Basic auth), Supabase |
| `engine/` | Served aluminum engine payload (matches `sketchup/`) |
| `public/` | `index.html`, `download.html`, `admin.html`, `downloads/CabinexAI_v5.rbz` |
| `supabase_monetization_schema.sql`, `supabase_tokens_migration.sql` | Metering/tokens |
| `create_user.js`, `test_*.js`, `test_eval.rb`, `vercel.json`, `.env.example` | Suppor + deploy |

### client_plugin/ — SketchUp-side streaming client
| File | Role |
|------|------|
| `online_cabinet_loader.rb` | Loads/syncs against the cloud (auth + stream) |
| `icons/` | 21 toolbar icons |

### analysis/ — strategy (from `docs/design`)
01 canonical job model · 02 aluminum construction method (the moat) · 03 BOM authority
· 04 workflow pipeline · 05–08 UI wireframes (site capture, studio web, workshop,
planner) · 09 phasing/risks · README.

---

## The online auth + streaming flow (how it fits together)
```
[SketchUp] loader.rb → login key (CBX-ENT-DEVOLY-8841)
   → cbx_cloud_loader.rb / online_cabinet_loader.rb
   → GET cloud /server.js  (license + token check, token accounting)
   → stream engine payload (engine/*) + public web + RBZ download
```
- Auth: license key + token balance; Supabase metering (optional).
- Streaming: engine is fetched from the cloud at run time (`cbx_cloud_loader.rb`);
  the RBZ is served with correct MIME from `/downloads/:filename`.

## Deploy (same as current app)
```
cd cloud
vercel --prod --yes
```
Live: `https://cabinex-cloud.vercel.app`. See `cloud/.env.example`.

## Notes
- This is a **referenced snapshot**; keep editing the canonical `cabinex_ai/` repo and
  re-sync here, or make this folder the living source and mirror to cloud.
- Board/legacy variants (`sketchup_ai_integration/`, `engine_board/`, board RBZs) were
  intentionally **not** copied.
