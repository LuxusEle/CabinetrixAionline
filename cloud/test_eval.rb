require 'net/http'
require 'uri'
require 'json'
require 'openssl'

uri = URI.parse('https://cabinex-cloud.vercel.app/api/auth/login')
req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
req.body = { license_key: 'CBX-PRO-9842-1104' }.to_json

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

res = http.request(req)
puts "Login response: #{res.code} -> #{res.body}"
auth_data = JSON.parse(res.body)
token = auth_data['token']

engine_uri = URI.parse('https://cabinex-cloud.vercel.app/api/engine/load')
eng_req = Net::HTTP::Post.new(engine_uri.path, {'Content-Type' => 'application/json'})
eng_req.body = { token: token }.to_json

eng_res = http.request(eng_req)
puts "Engine response: #{eng_res.code} -> Length: #{eng_res.body.length}"
eng_data = JSON.parse(eng_res.body)
engine_code = eng_data['engine']

# Mock Sketchup classes so we can test eval in standard Ruby
module Sketchup
  class Model; end
  def self.active_model; Model.new; end
end
module UI
  class HtmlDialog
    STYLE_DIALOG = 1
    def initialize(opts); end
    def set_html(h); end
    def set_file(f); end
    def add_action_callback(name); end
    def show; puts ">> HtmlDialog.show called successfully!"; end
    def close; end
    def visible?; false; end
  end
  def self.start_timer(d, r, &b); end
end
class Numeric
  def mm; self; end
  def inch; self * 25.4; end
end

begin
  eval(engine_code, TOPLEVEL_BINDING)
  puts ">> Engine evaluated successfully!"
  CabinexAI::HybridPlanner.show_dialog
  puts ">> CabinexAI::HybridPlanner.show_dialog passed!"
rescue => e
  puts ">> EVAL ERROR: #{e.message}"
  puts e.backtrace.first(10)
end
