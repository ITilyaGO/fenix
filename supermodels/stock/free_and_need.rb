module Stock end

class Stock::ArchCommon < PlainDoppel
  # PFX = :stock
  BODYMOD = :to_i

  # PROPS = [:name, :category_id, :created_at, :g, :bbid]
  # attr_accessor *PROPS
  
  def amount
    @body.to_i
  end

end

class Stock::Stock < Stock::ArchCommon
  PFX = :stock
  ENT_FOLDER = :archetype
end

class Stock::Free < Stock::Stock; end

class Stock::Need < Stock::ArchCommon
  PFX = :need
  ENT_FOLDER = :archetype
end

module StockFun
  def free id = nil
    return Stock::Free.all unless id
    return Stock::Free.find_all id if id.respond_to? :any?
    Stock::Free.find id
  end

  def need id = nil
    return Stock::Need.all unless id
    return Stock::Need.find_all id if id.respond_to? :any?
    Stock::Need.find id
  end
end

module Stock
  extend StockFun
end