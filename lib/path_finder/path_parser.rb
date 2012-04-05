class PathFinder::PathParser

  Condition = Struct.new(:operator, :key, :value)
  Token = Struct.new(:type, :data)


  module TokenHelper
    def tk(type, *data)
      Token.new(type, data)
    end
  end

  include TokenHelper

  STMT_SEP_RE = /\//
  KEYVAL_RE = /^([^=]+)=(.*)$/
  OP_RE = /^(AND|OR)(NOT)?$/i

  DEFAULT_OPERATOR = 'AND'

  def walk_path(path, &callback)

    # Dear code. I simply don't love you as much, as the code in that
    # other file. It's not your fault, it's just that the code in the
    # other file understands me, we somehow connect, it inspires me.
    # Anyway, all I wanted to say is: there's simply no way I'm going
    # to comment you!

    tokens = tokenize_path(path)

    scope, conditions, operator = nil, nil, nil

    scope_defaults = -> scope { [scope, [], DEFAULT_OPERATOR] }

    tokens.each do |token|
      if scope
        case token.type
        when :scope
          callback.call(scope, conditions, operator)
          scope, conditions, operator = *scope_defaults[*token.data]
        when :key_value
          conditions.push(Condition.new(operator, *token.data))
        when :operator
          operator = token.data.first
        else
          raise PathFinder::ParseError, "Unknown token: #{token[0]}. This should never happen."
        end
      else
        unless token[0] == :scope
          raise PathFinder::ParseError, "Unexpected token. Expected :scope, got #{token[0].inspect}. Tokens are: #{tokens.inspect}"
        end
        scope, conditions, operator = *scope_defaults[*token.data]
      end
    end

    callback.call(scope, conditions, operator) if scope

  end

  def tokenize_path(path)
    path.split(STMT_SEP_RE).map { |part|
      case part
      when KEYVAL_RE
        tk(:key_value, $~[1], $~[2])
      when OP_RE
        tk(:operator, $~[1])
      when ''
        nil
      else
        tk(:scope, part)
      end
    }.compact
  end

end
