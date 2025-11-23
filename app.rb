require 'sinatra'
require 'json'
require 'uri'
require 'pathname'

ARCHIVE_PATH = Pathname.new(ARGV[0] || '').freeze
ROUTING_TABLE = {}

puts 'Loading archive manifest, and populating routing table...'
JSON.load_file(ARCHIVE_PATH.join('manifest.json')).each do |f|
  uri = URI(f['file_url'])

  ROUTING_TABLE[uri.path] ||= {}

  warn("  Conflict found: #{f['file_url']}, skipping...") && next if ROUTING_TABLE[uri.path][uri.query.to_s]
  ROUTING_TABLE[uri.path][uri.query.to_s] = f.merge('host' => uri.host)
end

ROUTING_TABLE.freeze

DISCLAIMER = File.read(Pathname.new(__dir__).join('disclaimer.html')).freeze

get '/' do
  redirect to('/'), 308 unless params.all? { |(k, _)| k == 'p' || k == 'id' }

  route = ROUTING_TABLE['/'][request.query_string]
  halt 404, 'not found' unless route

  File.read(Pathname.new('.').join(ARCHIVE_PATH, route['host'], route['file_id'], 'index.html'))
    .gsub('<div id="map', "#{DISCLAIMER}<div id=\"map")
end

get '/health' do
  'OK'
end

get /.*/ do
  route = ROUTING_TABLE.dig(request.path, "")

  halt 404, 'not found' unless route

  send_file Pathname.new('.').join(ARCHIVE_PATH, route['host'], route['file_id'])
end

post /.*/ do
  halt 404, 'not found'
end
