
require 'spec_helper'

describe PathFinder do

  subject {
    described_class
  }

  before do
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
      results = subject.results(@path)
      results.entries.map {|entry|
        entry['id'].to_i
      }.should =~ @found_foos.map(&:id)
    end

    it "finds the right bars" do
      @path = '/bars/abc=123/foo/bar=baz'
      results = subject.results(@path)
      results.entries.map {|entry|
        entry['id'].to_i
      }.should =~ [@found_foos[0].bars[0].id]
    end
  end

end
