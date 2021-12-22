class Doppel < Cabie::Doppel
  LAYER = CabiePio

  def serializable_hash
    to_h
  end

  def errors
    {}
  end

  def formiz *args
    fill self.class.formize(*args).merge(merge: true)
  end
end

class Supermodel
  # ActiveRecord replacement for admin
end

module KSM
  # Kyoto Super Models
end
