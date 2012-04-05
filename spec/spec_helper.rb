
require File.join(File.dirname(__FILE__), '..', 'lib', 'query_builder')

require 'database_cleaner'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'query_builder_test',
  username: 'nil'
)

class Foo < ActiveRecord::Base
  has_many :bars
end

class Bar < ActiveRecord::Base
  belongs_to :foo
end

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
