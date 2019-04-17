class Timeline < ActiveRecord::Base
  enum duration: [ :day, :halfweek, :week ]
  belongs_to :order

  def self.duration_for_select
    durations.map do |type, _|
      [I18n.t("duration.#{type}"), type]
    end
  end
end