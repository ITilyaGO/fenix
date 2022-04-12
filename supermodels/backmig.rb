class KSM::Backmig < Doppel
  PFX = :mig

  PROPS = [:contents, :title, :created_at]
  attr_accessor *PROPS

  def push item, and_save: false
    ary = @contents ||= []
    ary << item unless ary.include?(item)
    @contents = ary.sort
    save if and_save
  end

  def pop item, and_save: false
    ary = @contents ||= []
    ary.delete item
    @contents = ary
    save if and_save
  end
end