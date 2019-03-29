class Client < ActiveRecord::Base
  has_many :orders
  belongs_to :place

  # Validations
  # validates_presence_of     :email, :tel, :message => 'не может быть пустым'
  # validates_presence_of     :org, :message => 'не может быть пустой'
  # validates_length_of       :email,    :within => 3..100
  # validates_format_of       :email,    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  def place_name
    place.nil? ? "" : place.name
  end

  def self.sync
    Client.delete_all
    Online::Account.all.each do |account|
      city = Place.where(:name => account.city).first
      # TODO: we cant add new places since db syncs sometimes
      # if city.nil?
      #   c = Place.create({ :name => account.city, :city_type => 1 })
      #   city = c.id
      # end
      dup = {:online_id => account.id, :name => account.name, :tel => account.tel, :place => city, :email => account.email, :org => account.org}
      dup[:online_place] = account.city if city.nil?
      Client.create(dup)
    end
  end

end
