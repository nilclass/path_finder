require 'active_record'
require 'active_support/core_ext'

module PathFinder

  # known to happen.
  class ScopeNotDefined < RuntimeError ; end
  # incredibly unlikely.
  class ParseError < RuntimeError ; end

  require File.expand_path('path_finder/path_parser.rb', File.dirname(__FILE__))
  require File.expand_path('path_finder/query_builder.rb', File.dirname(__FILE__))

  def self.results(path, limit=nil, offset=nil)
    ActiveRecord::Base.connection.execute(
      query_builder.build_query(path, limit, offset).
      to_sql.tap {|q| puts q }
    )
  end

  def self.query_builder
    @query_builder ||= QueryBuilder.new
  end

end
