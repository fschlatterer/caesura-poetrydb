require 'mongo'
require 'json'
require 'bson'

include Mongo

json_inputfile = ARGV[0]
mongo_uri = ENV['MONGODB_URI']
db_username = ENV['MONGODB_USER']
db_password = ENV['MONGODB_PASS']

# Use robust connection logic matching app/web.rb
options = {}
options[:user] = db_username if db_username
options[:password] = db_password if db_password

client = Mongo::Client.new(mongo_uri, options)
if ENV['MONGO_DATABASE']
  client = client.use(ENV['MONGO_DATABASE'])
end

db = client.database

coll = db.collection("poetry")
coll.delete_many({})

@data = JSON.parse(IO.read("#{json_inputfile}"))

@data['poem'].each do |poem|
  #coll.insert(poem)
  coll.insert_one(poem)
end
