class TimelineSection < ActiveRecord::Base
  belongs_to :order
  belongs_to :section

  enum weekday: Enums.weekdays
end