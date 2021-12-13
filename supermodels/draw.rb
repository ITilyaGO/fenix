class KSM::Draw < Doppel
  PFX = :draw

  PROPS = [:more, :type, :amount, :date, :sn, :sketch_id, :printed_at, :created_at, :printed]
  attr_accessor *PROPS
  attr_accessor :name
  
  def printed?
    @printed
  end

  def sortname
    "#{@date.strftime('%y%m%d')}-#{'%03i' % @sn.to_i}"
  end

  def addon
    "#{(' ' if @more)}#{@more}"
  end

  def displayname
    "#{@date.strftime('%d.%m.%y')} (#{@sn}) #{@type.capitalize}#{addon}"
  end

  class << self
    def nest(day = Date.today, num)
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
  end
end