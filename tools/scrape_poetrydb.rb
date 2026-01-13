require 'net/http'
require 'json'
require 'uri'

BASE_URL = "https://poetrydb.org"

def fetch_json(endpoint)
  url_str = "#{BASE_URL}#{endpoint}"
  uri = URI(url_str)
  # puts "Fetching: #{url_str}"
  response = Net::HTTP.get(uri)
  JSON.parse(response)
rescue => e
  puts "Error fetching #{endpoint}: #{e.message}"
  nil
end

puts "Fetching authors list..."
authors_data = fetch_json("/author")
unless authors_data && authors_data['authors']
  abort "Failed to fetch authors."
end

authors = authors_data['authors']
puts "Found #{authors.length} authors."

all_poems = []

authors.each_with_index do |author, index|
  # Encode author name: Space to %20
  encoded_author = author.gsub(' ', '%20')

  puts "[#{index + 1}/#{authors.length}] Fetching poems for: #{author}"
  poems = fetch_json("/author/#{encoded_author}")

  if poems.is_a?(Array)
    all_poems.concat(poems)
    # puts "  Found #{poems.length} poems."
  else
    puts "  No poems found (Response: #{poems.class})"
  end

  # Be nice to the API
  sleep 0.1
end

puts "Total poems fetched: #{all_poems.length}"

output = { "poem" => all_poems }

File.open("tools/poetry.json", "w") do |f|
  f.write(JSON.pretty_generate(output))
end

puts "Saved data to tools/poetry.json"
