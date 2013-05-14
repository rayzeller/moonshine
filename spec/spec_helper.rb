$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

LIB = File.join(File.dirname(__FILE__), "../lib/moonshine")
$LOAD_PATH.unshift(LIB)

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)

FERMENTERS = File.join(File.dirname(__FILE__), "fermenters")
$LOAD_PATH.unshift(FERMENTERS)

require "mongoid"
require "rspec"
require "moonshine"
require "active_record"
require "database_cleaner"

# These environment variables can be set if wanting to test against a database
# that is not on the local machine.
ENV["MONGOID_SPEC_HOST"] ||= "localhost"
ENV["MONGOID_SPEC_PORT"] ||= "27017"

# These are used when creating any connection in the test suite.
HOST = ENV["MONGOID_SPEC_HOST"]
PORT = ENV["MONGOID_SPEC_PORT"].to_i

# Moped.logger.level = Logger::DEBUG
# Mongoid.logger.level = Logger::DEBUG

# When testing locally we use the database named mongoid_test. However when
# tests are running in parallel on Travis we need to use different database
# names for each process running since we do not have transactions and want a
# clean slate before each spec run.
def database_id
  "mongoid_test"
end

def database_id_alt
  "mongoid_test_alt"
end

# Can we connect to MongoHQ from this box?
def mongohq_connectable?
  ENV["MONGOHQ_REPL_PASS"].present?
end

def purge_database_alt!
  session = Mongoid::Sessions.default
  session.use(database_id_alt)
  session.collections.each do |collection|
    collection.drop
  end
end

# Set the database that the spec suite connects to.
Mongoid.configure do |config|
  config.connect_to(database_id, consistency: :strong)
end

#Autoload every model for the test suite that sits in spec/app/models.
Dir[ File.join(MODELS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end

Dir[ File.join(LIB, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end

Dir[ File.join(FERMENTERS, "*.rb") ].sort.each do |file|
  name = File.basename(file, ".rb")
  autoload name.camelize.to_sym, name
end

module Rails

  def self.env
    ActiveSupport::StringInquirer.new("test")
  end

  class Application
  end
end

module MyApp
  class Application < Rails::Application
  end
end

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
ActiveRecord::Migration.create_table :orders do |t|
  t.string :store_id
  t.string :user_id
  t.time :time
  t.date :date
  t.integer :total
  t.integer :subtotal
  t.integer :sales_tax
  t.integer :calc_swipe
  t.integer :calc_cc_charge
  t.timestamps
end

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner[:active_record].strategy = :deletion
    DatabaseCleaner[:mongoid].strategy = :truncation
    DatabaseCleaner.clean
  end
   
  config.before(:each) do
    DatabaseCleaner.start
  end
   
  config.after(:each) do
    DatabaseCleaner.clean
  end
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular("address_components", "address_component")
end