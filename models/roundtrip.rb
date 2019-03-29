class Roundtrip < ActiveRecord::Base
  belongs_to :place

  def place_name
    place.nil? ? "" : place.name
  end
end