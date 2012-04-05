require 'active_record'
require 'active_support/core_ext'

module PathFinder

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

  require File.expand_path('path_finder/path_parser.rb', File.dirname(__FILE__))
  require File.expand_path('path_finder/query_builder.rb', File.dirname(__FILE__))

  def self.results(model, path, limit=nil, offset=nil)
    model.connection.execute(
      QueryBuilder.new(model, path).build_query(limit, offset).
      to_sql.tap {|q| puts q }
    )
  end

end
