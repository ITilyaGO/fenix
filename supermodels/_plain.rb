class PlainDoppel < Doppel
  MARSHAL = false
  BODYMOD = :itself
  IDMOD = :itself

  def validate
    true
  end

  def was_changed
    return true unless exist?
    body != @record.data.send(self.class::BODYMOD)
  end

  def gap
    body - @record.data.send(self.class::BODYMOD)
  end

  def save value
    @body = value
    return unless validate and was_changed
    super()
  end

  def diff amount
    save body + amount
  end

  def handle
    @key.public.send self.class::IDMOD
  end

  def body
    @body.send self.class::BODYMOD
  end

  def body_raw
    @body
  end

  class << self
    def query string, **args
      kyoto.query(onlyid(string).internal, **args, &dlpa)
    end

    def all **params
      kyoto.all(root_queue, params, &dlpa)
    end

    def find_all ids
      keys = ids.map{|id|kreator.onlyid(id)}
      kyoto.all_keys(keys, &dlpa)
    end
  end

end

module HandleSplittableE
  attr_accessor :spl
end

module HandleSplittable
  attr_accessor :splitted

  class << self
    attr_accessor :spl
  end

  def splitter
    @splitted = {}
    hs = handle.split self.class::SNAKE
    self.class.spl.each_with_index do |mody, i|
      @splitted[mody.first] = hs[i].send mody.last
    end
  end

  def after_init
    splitter
  end
end

class Cabie::Multi
  def flathash
    @records.map { |r| [r.handle, r] }.to_h
  end

  def flatless
    @records.map {|record| [record.handle, record.body] }.to_h
  end
end