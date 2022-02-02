class KSM::StickdayLimit < Doppel
  PFX = :stickday_limit

  PROPS = [:price, :delivery, :booked, :orders]
  attr_accessor *PROPS
  attr_reader :date

  def initialize(*args)
    super
    @date = Date.parse @id
    @price ||= 0
    @booked ||= 0
    @orders ||= {}
  end

  def fwd?
    fwd
  end

  def rebase global
    @price = global if @price == 0
    self
  end

  def self.find date
    return super(date) if date.respond_to? :size
    nid = date.strftime('%y%m%d')
    super nid
  end

  # def date
  #   Date.parse @id
  # end

  def avail
    price - booked
  end

  def avail_css
    case
    when !exist?
      nil
    when booked == 0
      :unbusy # :free
    when price > booked
      :unsure # :party
    when price <= booked
      :busy # :booked
    end
    # return :free if booked == 0

  end

  def month_id
    @date.strftime('%y%m')
  end

  def day_id
    @date.strftime('%y%m%d')
  end

  def self.newday date
    self.new id: date.strftime('%y%m%d')
  end

  # def to_r
  #   {
  #     d: day_id,
  #     price: @price,
  #     # o: orders
  #     fwd: @fwd,
  #     t: @type
  #   }.compact
  # end

  # def write
  #   fp = [:m, :stickday, :limits]
  #   kc = CabiePio.get(fp, month_id).data
  #   kc[day_id] = to_r
  #   CabiePio.set fp, month_id, kc
  # end

  # def self.point_mtx from, to
  #   kd = wonderbox(:stickday_point)
  #   to.step(from, -1).map do |d|
  #     kd
  #   end
  # end

  # def self.from rec
  #   date = Date.parse(rec[:d])
  #   price = rec[:price]
  #   fwd = rec[:fwd]
  #   type = rec[:t]

  #   self.new date, price, type: type, fwd: fwd
  # end

  # def self.field dates
  #   months = dates.map{|d|d.strftime('%y%m')}.uniq
  #   # TODO
  #   kc_limits = CabiePio.all_keys(months, [:m, :stickday, :limits]).flat.values.map(&:flatten).to_h

  #   sl = kc_limits.transform_values{|kc| self.from(rec)}
  #   result = dates.map{|d| [d, sl[d]]}.to_h
  #   result.each do |d, e|
  #     next if e

  #   end
  #   result

  # end

end