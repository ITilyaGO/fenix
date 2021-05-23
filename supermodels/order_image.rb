class KSM::OrderImage < Doppel
  PFX = :order_image

  PROPS = [:filename, :type, :size, :created_at]
  attr_accessor *PROPS

  attr_accessor :parent

  def ext
    id.split('.').last.to_sym
  end

  def is_picture?
    [:png, :jpeg, :jpg, :svg, :gif].include? ext
  end

  def self.born(order, fn)
    @parent = order
    @filename = fn
    nest
    # @filename = fn
    # @type = t
    # @size = s
    # self
  end

  def self.new_id
    orig_ext = @filename.split('.').last
    "#{@parent.to_s.rjust(3, '0')}-#{super}.#{orig_ext}"
  end

  def self.sroot_queue(order)
    Cabie::Key::Marshal.new([self::PFX, Doppel::ENT_FOLDER], order)
  end

  def self.all_for(order)
    kyoto.all(sroot_queue(order)).map{|e|doppel(e.key.public, e.data)}
  end
end

KSM::OrderImage.config do |c|
  c.gen = [:hex, 2]
end

# # Image order

# class KSM::ImageChain < Doppel
#   PFX = :image_chain
# end