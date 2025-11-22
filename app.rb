require 'sinatra'
require 'json'
require 'uri'
require 'pathname'

ARCHIVE_PATH = Pathname.new(ARGV[0] || '')
ROUTING_TABLE = {}

puts 'Loading archive manifest, and populating routing table...'
JSON.load_file(ARCHIVE_PATH.join('manifest.json')).each do |f|
  uri = URI(f['file_url'])

  ROUTING_TABLE[uri.path] ||= {}

  warn("  Conflict found: #{f['file_url']}, skipping...") && next if ROUTING_TABLE[uri.path][uri.query.to_s]
  ROUTING_TABLE[uri.path][uri.query.to_s] = f.merge('host' => uri.host)
end

get '/' do
  route = ROUTING_TABLE['/'][request.query_string]

  send_file Pathname.new('.').join(ARCHIVE_PATH, route['host'], route['file_id'], 'index.html')
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
  halt 404, 'not found' unless route
end
