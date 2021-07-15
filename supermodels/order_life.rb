class KSM::OrderLife < Doppel
  PFX = :order_life

  PROPS = [:stickday, :timeline, :modified, :created, :part_prepare, :part_current]
  attr_accessor *PROPS

  def initialize(args)
    super
    @stickday ||= []
    @part_prepare ||= {}
    @part_current ||= {}
  end

  def ts_prepare(section)
    @part_prepare[section] = Time.now
  end

  def ts_current(section)
    @part_current[section] = Time.now
  end

  # def self.new_id
  #   orig_ext = @filename.split('.').last
  #   "#{@parent.to_s.rjust(3, '0')}-#{super}.#{orig_ext}"
  # end

  def self.sroot_queue(order)
    Cabie::Key::Marshal.new([self::PFX, Doppel::ENT_FOLDER], order)
  end

  def self.all_for(order)
    kyoto.all(sroot_queue(order)).map{|e|doppel(e.key.public, e.data)}
  end
end
