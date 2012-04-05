
require 'spec_helper'

describe QueryBuilder::PathFinder do

  include QueryBuilder::StatementHelper

  subject {
    described_class.new(@model, @path)
  }

  before do
    @model = Foo
    @path = '/foos/bar=baz/AND/baz=foo/bars/abc=123/OR/cba=321'
  end

  describe "end results" do
    before do
      @found_foos = [
        # has right attribute and right bars
        Foo.create!(
          :bar => 'baz',
          :baz => 'foo',
          :bars => [
            Bar.create!(
              :abc => 123
            )
          ]
        ),
        Foo.create!(
          :bar => 'baz',
          :baz => 'foo',
          :bars => [
            Bar.create!(
              :abc => 789
            ),
            Bar.create!(
              :cba => 1523
            ),
            Bar.create!(
              :cba => 321
            )
          ]
        )
      ]
    end

    it "finds the right foos" do
      results = subject.results
      results.entries.map {|entry|
        entry['id'].to_i
      }.should =~ @found_foos.map(&:id)
    end

    it "finds the right bars" do
      @model = Bar
      @path = '/bars/abc=123/foo/bar=baz'
      results = subject.results
      results.entries.map {|entry|
        entry['id'].to_i
      }.should =~ [@found_foos[0].bars[0].id]
    end
  end

  describe "tokenizing" do

    it "recognizes scopes" do
      subject.tokens[0].should eq stmt(:scope, 'foos')
      subject.tokens[4].should eq stmt(:scope, 'bars')
    end

    it "recognizes key/value pairs" do
      subject.tokens[1].should eq stmt(:key_value, 'bar', 'baz')
      subject.tokens[3].should eq stmt(:key_value, 'baz', 'foo')
      subject.tokens[5].should eq stmt(:key_value, 'abc', '123')
      subject.tokens[7].should eq stmt(:key_value, 'cba', '321')
    end

    it "recognizes operators" do
      subject.tokens[2].should eq stmt(:operator, 'AND')
      subject.tokens[6].should eq stmt(:operator, 'OR')
    end

  end

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
