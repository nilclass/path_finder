PathFinder
==========

An attempt to convert web-friendly path to complex queries, by applying information derived from associations modeled using ActiveRecord.

This project is still WIP and far from done.

Example
-------

```ruby

require 'active_record'

class Foo < ActiveRecord::Base
  has_many :bars
end

class Bar < ActiveRecord::Base
  belongs_to :foo
end

require 'path_finder'

PathFinder.results(Foo, '/foos/x=heididei/bars/baz=10')
# equals sql:
#   SELECT DISTINCT foos.* FROM foos INNER JOIN bars ON bars.foo_id = foos.id WHERE foos.x = "heididei" AND bars.baz == 10
#
```

Abstract
--------

* Associations are fetched from ActiveRecord models (e.g. 'bars' -> Foo.has_many :bars)
* Returned result is from table of model Foo
* Joins are determined based on the information stored in the association, so most
  AR options like :table_name, :foreign_key, ... will (hopefully) work. has_many :through
  associations aren't implemented yet. Will happen.
* Queries are built using Arel
* This stuff is fun and hopefully useful at some point.


(c) 2012, Niklas E. Cathor

Released either under the terms of GPLv3 or the Ruby license (at your choice).
