class Stock::CommonMove < PlainDoppel
  PFX = :stock
  BODYMOD = :to_i

  # PROPS = [:name, :category_id, :created_at, :g, :bbid]
  # attr_accessor *PROPS
  
  def amount
    @body.to_i
  end

  def validate
    body.positive?
    true
  end

  class << self
    SNAKE = '_'.freeze

    def find arch, day
      super [arch, TimelineAssist.timeline_id(day)].join SNAKE
    end

    # def nest
    #   e = super
    #   e.fill(created_at: Time.now, name: 'Unknown', merge: true)
    #   e
    # end
  end
end

class Stock::Out < Stock::CommonMove
  ENT_FOLDER = :'common/d'
end

class Stock::In < Stock::CommonMove
  ENT_FOLDER = :'common/a'
end

class Stock::Cor < Stock::CommonMove
  ENT_FOLDER = :'common/c'

  def validate
    true
  end
end
