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

  ###
  ## /foo/bar=baz
  ##   => SELECT * FROM foo WHERE foo.bar = "baz"
  ##
  ##
  ##
  ##
  ##
  class PathFinder

    class ParseError < RuntimeError ; end
    class ScopeNotDefined < RuntimeError ; end

    include StatementHelper

    STMT_SEP_RE = /\//
    KEYVAL_RE = /^([^=]+)=(.*)$/
    OP_RE = /^(AND|OR)(NOT)?$/i

    DEFAULT_OPERATOR = 'AND'

    attr :model
    attr :path
    attr :tokens

    def initialize(model, path)
      @model = model
      @path = path
      @tokens = tokenize_path
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
      walk_path do |scope, conditions, operator|
        unless applied_scopes[scope]
          joins = lookup_joins(model, scope)
          if joins.empty?
            raise ScopeNotDefined, "Scope #{scope.inspect} not defined for model #{model.name}"
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
      puts "APPLYING JOIN #{join.inspect}"
      return query.
        join(
          join_table,
          type == :inner ? Arel::Nodes::InnerJoin : Arel::Nodes::OuterJoin
        ).
        on(
          join_table[foreign_key].
          eq(table[primary_key])
        )
    end

    def lookup_joins(model, scope)
      # in the future this might look up nested joins as well.
      [self.class.lookup_join(model, scope)].compact
    end

    def self.lookup_join(from, to)
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

    def self.lookup_association(model, scope)
      model.reflect_on_all_associations.each do |reflection|
        if reflection.name == scope.to_sym
          return reflection
        end
      end
      return nil
    end

    def walk_path(&callback)
      scope, conditions, operator = nil, nil, nil

      init_scope = -> token {
        scope = token[1]
        conditions = []
        operator = DEFAULT_OPERATOR
      }

      tokens.each do |token|
        if scope
          case token[0]
          when :scope
            callback.call(scope, conditions, operator)
            init_scope[token]
          when :key_value
            conditions.push([operator, token[1], token[2]])
          when :operator
            operator = token[1]
          else
            raise ParseError, "Unknown token: #{token[0]}. This should never happen."
          end
        else
          unless token[0] == :scope
            raise ParseError, "Unexpected token. Expected :scope, got #{token[0].inspect}. Tokens are: #{tokens.inspect}"
          end
          init_scope[token]
        end
      end

      callback.call(scope, conditions, operator) if scope

    end

    protected

    def tokenize_path
      @path.split(STMT_SEP_RE).map { |part|
        case part
        when KEYVAL_RE
          stmt(:key_value, $~[1], $~[2])
        when OP_RE
          stmt(:operator, $~[1])
        when ''
          nil
        else
          stmt(:scope, part)
        end
      }.compact
    end

  end

end
