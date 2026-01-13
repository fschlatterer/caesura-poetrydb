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

    # Auto-populate database if empty
    if db.collection("poetry").count_documents == 0
      puts "Database is empty. Seeding data..."
      begin
        # Check for full dataset first, then fallback to test data
        real_data = File.join(File.dirname(__FILE__), '../tools/poetry.json')
        test_data = File.join(File.dirname(__FILE__), '../tools/test.json')

        seed_file = File.exist?(real_data) ? real_data : test_data

        if File.exist?(seed_file)
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
          end
        else
          puts "No seed file found (checked #{real_data} and #{test_data})"
        end
      rescue => e
        puts "Error seeding database: #{e.message}"
      end
    else
      puts "Database already contains data."
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
