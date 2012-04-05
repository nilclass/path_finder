
require 'spec_helper'

describe PathFinder::QueryBuilder do

  describe ".lookup_association" do
    it "finds Foo#bars" do
      reflection = described_class.lookup_association(Foo, 'bars')
      reflection.klass.should be Bar
      reflection.active_record.should be Foo
      reflection.macro.should be :has_many
    end

    it "finds Bar#foo" do
      reflection = described_class.lookup_association(Bar, 'foo')
      reflection.klass.should be Foo
      reflection.active_record.should be Bar
      reflection.macro.should be :belongs_to
    end
  end

  describe ".lookup_join" do
    it "finds Foo#bars" do
      join = described_class.lookup_join(Foo, 'bars')
      join.should eq [
        Bar.arel_table,
        'foo_id',
        Foo.arel_table,
        'id',
        :outer
      ]
    end

    it "finds Bar#foos" do
      join = described_class.lookup_join(Bar, 'foo')
      join.should eq [
        Foo.arel_table,
        'id',
        Bar.arel_table,
        'foo_id',
        :inner
      ]
    end

  end
end
