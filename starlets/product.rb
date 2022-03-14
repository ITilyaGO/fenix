module SL
end

class SL::Product
  attr_accessor :arn, :k1c

  def initialize product
    @arn = CabiePio.get([:product, :archetype], product).data
    @k1c = CabiePio.get([:product, :k1c], product).data
  end

end