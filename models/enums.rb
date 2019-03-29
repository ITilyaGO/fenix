class Enums < ActiveRecord::Base
  enum weekday: [ :mo, :tu, :we, :th, :fr ]
end