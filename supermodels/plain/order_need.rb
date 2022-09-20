class KSM::OrderNeed < PlainDoppel
  PFX = :need
  ENT_FOLDER = :order
  BODYMOD = :to_i
  # IDMOD = :to_i
  SNAKE = '_'.freeze

  include HandleSplittable
  extend HandleSplittableE

  class << self
    def find arch, ol, order      
      super [arch, ol, order].join SNAKE
    end
  end
end

KSM::OrderNeed.config do |c|
  c.spl = {
    :arch => :itself,
    :line => :itself,
    :order => :to_i
  }
end