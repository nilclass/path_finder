class PathFinder::PathParser

  include PathFinder::StatementHelper

  STMT_SEP_RE = /\//
  KEYVAL_RE = /^([^=]+)=(.*)$/
  OP_RE = /^(AND|OR)(NOT)?$/i

  DEFAULT_OPERATOR = 'AND'

  attr :tokens

  def initialize(path)
    @path = path
    @tokens = tokenize_path
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
          raise PathFinder::ParseError, "Unknown token: #{token[0]}. This should never happen."
        end
      else
        unless token[0] == :scope
          raise PathFinder::ParseError, "Unexpected token. Expected :scope, got #{token[0].inspect}. Tokens are: #{tokens.inspect}"
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
