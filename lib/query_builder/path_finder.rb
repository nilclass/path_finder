###
## /foo/bar=baz
##   => SELECT * FROM foo WHERE foo.bar = "baz"
##
##
##
##
##
class QueryBuilder::PathFinder

  attr :model
  attr :path

  def initialize(model, path)
    @model = model
    @path = path
    @parser = QueryBuilder::PathParser.new(@path)
  end

  def tokens
    @parser.tokens
  end

  def results(offset=nil, limit=nil)
    model.connection.execute(
      build_query.
      skip(offset).
      take(limit).
      to_sql.tap {|q| puts q }
      )
  end

  def build_query
    query = model.arel_table.project(Arel.sql('*'))
    applied_scopes = {
      model.table_name => true
    }
    puts "WALKING"
    @parser.walk_path do |scope, conditions, operator|
      unless applied_scopes[scope]
        joins = lookup_joins(model, scope)
        if joins.empty?
          raise QueryBuilder::ScopeNotDefined, "Scope #{scope.inspect} not defined for model #{model.name}"
        end
        query = joins.inject(query) do |q, join|
          apply_join(q, join)
        end
        applied_scopes[scope] = true
      end

      conditions.each do |operator, key, value|
      end
    end

    return query
  end

  def apply_join(query, join)
    join_table, foreign_key, table, primary_key, type = *join
    type_node = (type == :inner ? Arel::Nodes::InnerJoin : Arel::Nodes::OuterJoin)
    puts "APPLYING JOIN #{join.inspect}"
    return query.
      join(join_table, type_node).
      on(join_table[foreign_key].eq(table[primary_key]))
  end

  def lookup_joins(model, scope)
    # in the future this might look up nested joins as well.
    [self.class.lookup_join(model, scope)].compact
  end

  class << self

    def lookup_join(from, to)
      if reflection = lookup_association(from, to)
        if reflection.macro == :belongs_to
          return [
            reflection.klass.arel_table,
            reflection.association_primary_key,
            reflection.active_record.arel_table,
            reflection.foreign_key,
            :inner
          ]
        else
          return [
            reflection.klass.arel_table,
            reflection.foreign_key,
            reflection.active_record.arel_table,
            reflection.association_primary_key,
            :outer
          ]
        end
      end
    end

    def lookup_association(model, scope)
      model.reflect_on_all_associations.each do |reflection|
        if reflection.name == scope.to_sym
          return reflection
        end
      end
      return nil
    end

  end

end
