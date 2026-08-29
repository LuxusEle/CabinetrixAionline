const fs = require('fs');
const path = require('path');

const server = require('./server.js');

// Test bundle extraction
const engineDir = path.join(__dirname, 'engine');
let hybridEngineRb = fs.readFileSync(path.join(engineDir, 'cbx_hybrid_engine.rb'), 'utf8');
let hybridPlannerRb = fs.readFileSync(path.join(engineDir, 'cbx_hybrid_planner.rb'), 'utf8');
const plannerHtml = fs.readFileSync(path.join(engineDir, 'cbx_hybrid_planner.html'), 'utf8');
const reportHtml = fs.readFileSync(path.join(engineDir, 'cbx_workshop_report.html'), 'utf8');

hybridPlannerRb = hybridPlannerRb.replace(/engine_path\s*=\s*File\.expand_path.*?\n/g, '# Engine pre-loaded in memory\n');
hybridPlannerRb = hybridPlannerRb.replace(/load\s+engine_path.*?\n/g, '');
hybridPlannerRb = hybridPlannerRb.replace(/HTML_PATH\s*=\s*File\.join\(.*?\)/g, 'HTML_PATH = ""');
hybridPlannerRb = hybridPlannerRb.replace(/html_content\s*=\s*File\.read\(.*?\)/g, 'html_content = CabinexAI::CloudUI::PLANNER_HTML');
hybridPlannerRb = hybridPlannerRb.replace(/report_html\s*=\s*File\.join\(.*?\)/g, 'report_html = ""');
hybridPlannerRb = hybridPlannerRb.replace(/report_dialog\.set_file\(.*?\)/g, 'report_dialog.set_html(CabinexAI::CloudUI::REPORT_HTML)');

console.log('Does plannerHtml have closing tags?', plannerHtml.includes('</html>'));
console.log('Does reportHtml have closing tags?', reportHtml.includes('</html>'));

// Check for any unescaped quotes or backticks in the bundled code
const bundled = `
  module CabinexAI
    module CloudUI
      PLANNER_HTML = ${JSON.stringify(plannerHtml)}
      REPORT_HTML = ${JSON.stringify(reportHtml)}
    end
  end

  ${hybridEngineRb}
  ${hybridPlannerRb}
`;

console.log('Total bundled length:', bundled.length);
console.log('Checking for syntax issues or remaining __dir__ in planner...');
const lines = hybridPlannerRb.split('\n');
lines.forEach((l, idx) => {
  if (l.includes('__dir__') || l.includes('File.read') || l.includes('File.join')) {
    console.log(`Line ${idx+1}: ${l}`);
  }
});
