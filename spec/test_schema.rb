
ActiveRecord::Schema.define do |s|

  s.create_table :foos, :force => true do |t|
    t.string :bar
    t.string :baz
  end

  s.create_table :bars, :force => true do |t|
    t.belongs_to(:foo)
    t.integer :abc
    t.integer :cba
  end

end
