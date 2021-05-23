class Doppel < Cabie::Doppel
  LAYER = CabiePio

  def serializable_hash
    to_h
  end

  def errors
    {}
  end
end

class Supermodel
  # ActiveRecord replacement for admin
end

module KSM
  # Kyoto Super Models
end
