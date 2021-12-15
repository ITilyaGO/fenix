class KSM::Draw < Doppel
  PFX = :draw

  PROPS = [:more, :type, :amount, :date, :sn, :sketch_id, :printed_at, :created_at, :printed]
  attr_accessor *PROPS
  attr_accessor :name
  
  def printed?
    @printed
  end

  def common
    "#{@type&.capitalize}#{@sn}"
  end

  def sortname
    "#{@date.strftime('%y%m%d')}-#{'%03i' % @sn.to_i}"
  end

  def addon
    "#{(' ' if @more)}#{@more}"
  end

  def displayname
    "#{@date.strftime('%d.%m.%y')} (#{@sn}) #{@amount}_#{@type&.capitalize}#{addon}"
  end

  class << self
    def nest(day = Date.today, num)
      @dday = day
      e = super()
      e.fill(created_at: Time.now, date: day, sn: num, merge: true)
      e
    end

    def schema
      {
        type: [:to_sym],
        amount: [:to_i],
        sn: [:to_i]
      }
    end

    def idtime day: Time.new
      day.strftime('%y%m%d_%H%M%S')
    end

    def new_id
      idtime(day: @dday)[0...6] + super
    end

    def day_queue day
      Cabie::Key::Marshal.new([self::PFX, Cabie::Doppel::ENT_FOLDER], day)
    end

    def allday(param)
      kyoto.all(day_queue(param)).map{|e|doppel(e.key.public, e.data)}
    end
  end
end

KSM::Draw.config do |c|
  c.gen = [:hex, 1]
end