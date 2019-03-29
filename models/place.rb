class Place < ActiveRecord::Base
  belongs_to :region
  enum city_type: [ '', :city, :church, :other ]

  def region_name
    region.nil? ? '' : region.name
  end

  def self.sync
    ActiveRecord::Base.connection.exec_query('DROP TABLE IF EXISTS places_sync;')
    ActiveRecord::Base.connection.exec_query('CREATE TEMPORARY TABLE places_sync AS SELECT * FROM places;')
    Place.delete_all
    Place.record_timestamps = false
    Online::Place.where('created_at IS NULL OR updated_at >= created_at').each do |place|
      sql = "SELECT region_id FROM places_sync WHERE id = #{place.id};"
      with_region = ActiveRecord::Base.connection.exec_query(sql).first
      dup = place.attributes.merge({:id => place.id})
      dup.attributes.merge!({:region_id => with_region["region_id"]}) unless with_region.nil?
      Place.create(dup)
    end
    Place.record_timestamps = true
    ActiveRecord::Base.connection.exec_query('DROP TABLE places_sync;')
  end

end
