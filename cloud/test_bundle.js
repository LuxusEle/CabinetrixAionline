const fs = require('fs');
const path = require('path');

const engineDir = path.join(__dirname, 'engine');
let hybridPlannerRb = fs.readFileSync(path.join(engineDir, 'cbx_hybrid_planner.rb'), 'utf8');

console.log('--- Original first 15 lines ---');
console.log(hybridPlannerRb.split('\n').slice(0, 15).join('\n'));

hybridPlannerRb = hybridPlannerRb.replace(/engine_path\s*=\s*File\.expand_path.*?\n/g, '# Engine pre-loaded in memory\n');
hybridPlannerRb = hybridPlannerRb.replace(/load\s+engine_path.*?\n/g, '');
hybridPlannerRb = hybridPlannerRb.replace(/HTML_PATH\s*=\s*File\.join\(.*?\)/g, 'HTML_PATH = ""');
hybridPlannerRb = hybridPlannerRb.replace(/html_content\s*=\s*File\.read\(.*?\)/g, 'html_content = CabinexAI::CloudUI::PLANNER_HTML');
hybridPlannerRb = hybridPlannerRb.replace(/report_html\s*=\s*File\.join\(.*?\)/g, 'report_html = ""');
hybridPlannerRb = hybridPlannerRb.replace(/report_dialog\.set_file\(.*?\)/g, 'report_dialog.set_html(CabinexAI::CloudUI::REPORT_HTML)');

console.log('\n--- Transformed first 25 lines ---');
console.log(hybridPlannerRb.split('\n').slice(0, 25).join('\n'));
