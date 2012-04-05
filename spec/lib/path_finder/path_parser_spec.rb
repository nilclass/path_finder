
require 'spec_helper'

describe PathFinder::PathParser do

  include PathFinder::PathParser::TokenHelper

  before :all do
    @path = '/foos/bar=baz/AND/baz=foo/bars/abc=123/OR/cba=321'
  end

  describe "tokenizing" do

    before :all do
      @tokens = subject.tokenize_path(@path)
    end

    it "recognizes scopes" do
      @tokens[0].should eq tk(:scope, 'foos')
      @tokens[4].should eq tk(:scope, 'bars')
    end

    it "recognizes key/value pairs" do
      @tokens[1].should eq tk(:key_value, 'bar', 'baz')
      @tokens[3].should eq tk(:key_value, 'baz', 'foo')
      @tokens[5].should eq tk(:key_value, 'abc', '123')
      @tokens[7].should eq tk(:key_value, 'cba', '321')
    end

    it "recognizes operators" do
      @tokens[2].should eq tk(:operator, 'AND')
      @tokens[6].should eq tk(:operator, 'OR')
    end

  end

  describe "walking" do

    before :all do
      @yielded_values = []
      @block = -> *values { @yielded_values.push values }
      subject.walk_path(@path, &@block)
    end

    it "yields each scope" do
      @yielded_values[0][0].should eq 'foos'
      @yielded_values[1][0].should eq 'bars'
    end

    it "yields all conditions" do
      @yielded_values[0][1].should eq [
        PathFinder::PathParser::Condition.new("AND", "bar", "baz"),
        PathFinder::PathParser::Condition.new("AND", "baz", "foo"),
      ]
      @yielded_values[1][1].should eq [
        PathFinder::PathParser::Condition.new("AND", "abc", "123"),
        PathFinder::PathParser::Condition.new( "OR", "cba", "321"),
      ]
    end

  end

end
