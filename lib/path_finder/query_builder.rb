class PathFinder::QueryBuilder

  # no comment.
  def initialize
    @parser = PathFinder::PathParser.new
  end

  # no comment.
  def build_query(path, limit=nil, offset=nil)
    query = nil
    model = nil
    scope_tables = {}

    ###########################################
    ###########################################
    ###                                     ###
    ### Let's take a walk, down the path... ###
    ###                                     ###
    ###                           *     *   ###
    ###    -       next to    * *     *     ###
    ###  \-     *    the     *      *       ###
    ###   \ || *    trees, *      *         ###
    ###    \||/&      * * *     *           ###
    ###     ||      *     OR   *            ###
    ###     ||     *     * * *              ###
    ###            *    *     along         ###
    ###           * AND *       the         ###
    ###          *     *         mighty     ###
    ###          *     *       TokenRiver,  ###
    ###                                     ###
    ###               of a bunch of         ###
    ###                 slash separated     ###
    ###                     foo=bar.        ###
    ###                                     ###
    ###########################################
    ###########################################

    @parser.walk_path(path) do |scope, conditions, operator|
      # mighty is the river of tokens, but even mightier, the
      # ocean of data, towards which it flows.
      # let's change that!
      # oh, I know a nice trick! Let's trick the user, by giving
      # them back not the data from everywhere he asked us about,
      # but just from the first place we visit.
      #
      # That way our walk isn't any shorter, but at least our customers,
      # that actually execute the query don't have logistics hell, when
      # they need to swallow the data. or be swallowed by it.
      #
      # As was said before, it is mighty that ocean of data. And if too greedy,
      # your slice from that cake (yes, indeed, ocean == cake as you will find
      # out if you digg deep enough) might just turn into a tsunami and tear
      # down all of your walls.
      #
      # Happy building.
      #
      unless model
        # no model yet? let's take the first scope we can get!
        model = lookup_model(scope)
        # oh look, here comes a table! let's remember that one, so we
        # can look up columns on it later.
        scope_tables[scope] = model.arel_table
        # (this is fun...)
        query = prepare_query(model, limit, offset)
      end

      # Now I have a model, which I can ask for the tables of other scopes
      # in the future.
      unless scope_tables[scope]
        # greetings, new scope, long time no see!
        # (who the fuck are you?)
        joins = lookup_joins(model, scope)

        if joins.empty?
          # no one seems to know you, get out of the way!
          raise PathFinder::ScopeNotDefined, "Scope #{scope.inspect} not defined for model #{model.name}"
        end

        table = nil

        joins.each do |join|
          # let's join hands, and become a query!
          table = apply_join(query, join)
        end

        scope_tables[scope] = table
      end

      # in case we didn't know our table before, now we do!
      table = scope_tables[scope]

      query.where( # query wants to be fed conditions!
        # let's start with nothing and add to it.
        conditions.inject(nil) { |condition_node, condition|
          # we should comply to the local table manners, that way it's
          # going to be a fine meal, with lots of information exchange.
          node = build_condition_node(
            table,
            condition
          )

          condition_node = (condition_node ?
            condition_node.
            __send__(
              # gladly for us, our operators are named exactly like the methods
              # an Arel::Table provides us with. lucky we!
              condition.operator.downcase.to_sym,
              node
            ) :
            # Sorry, you're a first node of hopefully many. You don't get
            # to choose your operator. You will be evaluated, no matter what!
            node
          )
        }
      )
    end

    return query
  end

  def lookup_model(scope)
    # Holla, die Waldfee!
    scope.singularize.camelize.constantize
  end

  def prepare_query(model, limit, offset)
    # ooohhh jeeezz!
    # how do we lead that whole limit / offset voodoo onto the righteous path?
    #
    # quite simple. by magic.
    # even more simpler, with a plain dash.
    # one like this: -
    #
    #   If you like this idea, go tell the parser it should invent that token.
    #   Every statement before that token is supposed to be a key/value pair,
    #   providing meta information for the query!
    #
    # This is how it could look like:
    #
    #   /limit=7/offset=42/-/foos/bar=baz/
    #
    # Another option would be to append it, which might be a lot more handy
    # for the craftsmenship of manual path cutting.
    #
    return model.arel_table.
      project(model.arel_table.columns).
      distinct.
      take(limit).
      skip(offset)
  end

  def build_condition_node(table, condition)
    # TODO: do different things with different types and differently formatted values.
    table[condition.key].eq(condition.value)
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

  # no comment.
  def lookup_joins(model, scope)
    # oh, but in the future this might look up nested joins as well.
    [self.class.lookup_join(model, scope)].compact
  end

  class << self

    # no comment.
    def lookup_join(from, to)
      if reflection = lookup_association(from, to)
        if reflection.macro == :belongs_to
          return [
            reflection.klass.arel_table,
            reflection.association_primary_key,
            reflection.active_record.arel_table,
            reflection.foreign_key,
            # we make the bold assumption, that whenever some entity "belongs to"
            # another, and that other entity has specified conditions, that we
            # don't take *any* interest in rows from our entity, which have no
            # such relationship to any row from the other entity.
            # hence we go for the inner join.
            #
            # this course of action may or may not be wise, instead one (being
            # a creator of paths) might expect scopes to be fully left-associative,
            # i.e. if one specifies entity "foos" first, one is primarily
            # interested in everything that happens in "foos", regardless what
            # other tables say, with the exception of those rows of "foos", which
            # actually have a "belonging" association to such other table, and
            # can therefore be removed based on information found in that other
            # table.
            #
            # another point of view might be, that we should simply provide
            # means of controlling the way a particular association is expected
            # to be joined over. that however, would be quite boring and render
            # this and the two previous paragraphs utterly useless.
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

    # no comment.
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
