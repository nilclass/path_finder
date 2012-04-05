require 'active_record'
require 'active_support/core_ext'

module QueryBuilder

  # In the future stmt() might do more than just return it's arguments.
  # With this helper, the structure of a statement can change, without
  # breaking the specs.
  module StatementHelper
    def stmt(type, *data)
      [type, *data]
    end
  end

  class ScopeNotDefined < RuntimeError ; end
  class ParseError < RuntimeError ; end

  require File.expand_path('query_builder/path_parser.rb', File.dirname(__FILE__))
  require File.expand_path('query_builder/path_finder.rb', File.dirname(__FILE__))

end
