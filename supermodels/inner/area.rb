module KSI end

class KSI::Area < Doppel
  PFX = :area

  PROPS = [:contents, :title, :created_at]
  attr_accessor *PROPS

  def initialize params
    super
    @contents ||= []
  end

  def push item, and_save: true
    ary = @contents ||= []
    ary << item unless ary.include?(item)
    @contents = ary
    save if and_save
  end

  def pop item, and_save: true
    ary = @contents ||= []
    ary.delete item
    @contents = ary
    save if and_save
  end

  class << self
    def nest place
      @nest_place = place
      e = super()
      e.fill(created_at: Time.now, merge: true)
      e
    end

    def new_id
      @nest_place
    end
  end
end

module AreaMap
  def which place
    area = KSI::Area.find place
    find_all area.contents
  end

  def global
    which :RU
  end
end