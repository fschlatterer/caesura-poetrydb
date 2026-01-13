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

    db_username = ENV['MONGODB_USER']
    db_password = ENV['MONGODB_PASS']

    # Try to extract database name from URI, or fall back to explicit env var
    db_name = mongo_uri[%r{/([^/\?]+)(\?|$)}, 1] || ENV['MONGO_DATABASE']

    if db_name.nil? || db_name.empty?
       raise "Could not determine database name. Please include it in MONGODB_URI or set MONGO_DATABASE environment variable."
    end

    client = Mongo::Client.new(mongo_uri, :database => db_name, :user => db_username, :password => db_password)
    db = client.database

    set :root, File.dirname(__FILE__)
    set :public_folder, './public'

    set :mongo_client, client
    set :mongo_db, db
    set :poetry_coll, db.collection("poetry")
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
