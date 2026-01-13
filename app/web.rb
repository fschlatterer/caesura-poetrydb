require 'sinatra'
require 'mongo'
require 'json'

include Mongo

class Web < Sinatra::Base
  configure do
    # Check common environment variable names for MongoDB connection string
    mongo_uri = ENV['MONGODB_URI'] || ENV['MONGO_URI'] || ENV['MONGO_URL'] || ENV['MONGOLAB_URI'] || ENV['MONGOHQ_URL']

    if mongo_uri.nil? || mongo_uri.empty?
      puts "FATAL: MongoDB connection string not found."
      puts "Available Environment Variables: #{ENV.keys.sort.join(', ')}"
      raise "MongoDB connection string not found. Please set MONGODB_URI (or MONGO_URL, MONGOLAB_URI) environment variable. See logs for available keys."
    end

    # Prepare options for Mongo Client
    options = {}
    options[:user] = ENV['MONGODB_USER'] if ENV['MONGODB_USER']
    options[:password] = ENV['MONGODB_PASS'] if ENV['MONGODB_PASS']

    # Initialize client (let driver parse the URI for database name initially)
    client = Mongo::Client.new(mongo_uri, options)

    # If MONGO_DATABASE is explicitly set, use it
    if ENV['MONGO_DATABASE']
      client = client.use(ENV['MONGO_DATABASE'])
    end

    db = client.database

    set :root, File.dirname(__FILE__)
    set :public_folder, './public'

    set :mongo_client, client
    set :mongo_db, db
    set :poetry_coll, db.collection("poetry")

    # Database Maintenance and Auto-Seeding
    begin
      real_data = File.join(File.dirname(__FILE__), '../tools/poetry.json')
      test_data = File.join(File.dirname(__FILE__), '../tools/test.json')

      should_seed = false
      seed_file = nil

      if File.exist?(real_data)
        # We have real data. Check if we need to upgrade from test data.
        # Test if "William Shakespeare" is missing (he is in real data, not in test data)
        shakespeare_count = db.collection("poetry").find(author: "William Shakespeare").limit(1).count

        if shakespeare_count == 0
          puts "Detected missing Real Data (Shakespeare not found). Initiating database reset and upgrade..."
          db.collection("poetry").delete_many({}) # Wipe existing (test) data
          should_seed = true
          seed_file = real_data
        end
      elsif db.collection("poetry").count_documents == 0
        # No real data file, but DB is empty. Seed with whatever we have (test data).
        should_seed = true
        seed_file = File.exist?(test_data) ? test_data : nil
        puts "Database is empty. Seeding with available data..."
      else
        puts "Database already contains data."
      end

      if should_seed && seed_file
        puts "Loading seed data from #{seed_file}..."
        data = JSON.parse(File.read(seed_file))
        if data['poem']
          # Batch insert to avoid memory/timeout issues if large
          poems = data['poem']
          batch_size = 1000
          poems.each_slice(batch_size) do |batch|
            db.collection("poetry").insert_many(batch)
          end
          puts "Successfully inserted #{poems.count} poems."
        else
          puts "Invalid seed file format (missing 'poem' key)."
        end
      elsif should_seed
        puts "No seed file found (checked #{real_data} and #{test_data})"
      end

    rescue => e
      puts "Error during database maintenance: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

  def json_status(code, reason)
    status code
    {
      :status => code,
      :reason => reason
    }.to_json
  end

  after do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  get '/' do
    redirect '/index.html'
  end
end

require_relative 'helpers/init'
require_relative 'routes/init'
