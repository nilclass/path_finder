
require 'spec_helper'

describe PathFinder::PathParser do

  include PathFinder::StatementHelper

  subject {
    described_class.new(@path)
  }

  before do
    @path = '/foos/bar=baz/AND/baz=foo/bars/abc=123/OR/cba=321'
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

end
