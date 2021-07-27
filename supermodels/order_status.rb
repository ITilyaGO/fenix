class KSM::OrderStatus < Doppel
  PFX = :order_status

  PROPS = [:pstate, :pflag, :global, :gflag]
  attr_accessor *PROPS

  BIT_STATES = {
    current: 1,
    finished: 2,
    anew: 3,
    shipped: 4,
    canceled: 5,
    draft: 6,
    prepare: 21
  }.freeze

  BIT_FLAGS = {
    blink: 2
  }.freeze

  def initialize(args)
    super
    @pstate ||= {}
    @pflag ||= {}
  end

  def sets(section, state)
    @pstate[section] = BIT_STATES[state]
  end

  def setg(state)
    @global = BIT_STATES[state]
  end

  def set_prepare(section)
    @pstate[section] = BIT_STATES[:prepare]
  end

  def set_current(section)
    @pstate[section] = BIT_STATES[:current]
  end

  def prepare?(section)
    @pstate[section] == BIT_STATES[:prepare]
  end

  def what?(state, section = nil)
    state = [state] unless state.respond_to? :include?
    return state.include? BIT_STATES.key(@global) if section.nil?
    state.include? BIT_STATES.key(@pstate[section])
  end

  def present?(section = nil)
    return BIT_STATES.key(@global) if section.nil?
    BIT_STATES.key(@pstate[section])
  end

  def state(section = nil)
    present?(section) || :none
  end

  # # def self.new_id
  # #   orig_ext = @filename.split('.').last
  # #   "#{@parent.to_s.rjust(3, '0')}-#{super}.#{orig_ext}"
  # # end

  # def self.sroot_queue(order)
  #   Cabie::Key::Marshal.new([self::PFX, Doppel::ENT_FOLDER], order)
  # end

  # def self.all_for(order)
  #   kyoto.all(sroot_queue(order)).map{|e|doppel(e.key.public, e.data)}
  # end
end
