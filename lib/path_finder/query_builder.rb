class PathFinder::QueryBuilder

  attr :model
  attr :path

  def initialize(model, path)
    @model = model
    @path = path
    @parser = PathFinder::PathParser.new(@path)
  end

  def tokens
    @parser.tokens
  end

  def build_query(limit=nil, offset=nil)
    query = model.
      arel_table.
      project(model.arel_table.columns).
      distinct.
      take(limit).
      skip(offset)

    scope_tables = {
      model.table_name => model.arel_table
    }
    @parser.walk_path do |scope, conditions, operator|
      unless scope_tables[scope]
        joins = lookup_joins(model, scope)
        if joins.empty?
          raise PathFinder::ScopeNotDefined, "Scope #{scope.inspect} not defined for model #{model.name}"
        end

        table = nil

        joins.each do |join|
          table = apply_join(query, join)
        end

        # the table joined over last, is the namespace
        # of the columns used in conditions.
        scope_tables[scope] = table
      end

      table = scope_tables[scope]

      condition_node = nil

      conditions.each do |operator, key, value|
        node = build_condition_node(table, key, value)
        condition_node = (condition_node ?
          condition_node.__send__(operator.downcase.to_sym, node) :
          node
        )
      end

      query.where(condition_node)
    end

    return query
  end

  def build_condition_node(table, key, value)
    # TODO: do different things with different types and differently formatted values.
    table[key].eq(value)
  end

  def apply_join(query, join)
    join_table, foreign_key, table, primary_key, type = *join
    type_node = (type == :inner ? Arel::Nodes::InnerJoin : Arel::Nodes::OuterJoin)
    query.join(
      join_table, type_node
    ).on(
      join_table[foreign_key].eq(table[primary_key])
    )
    return join_table
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
