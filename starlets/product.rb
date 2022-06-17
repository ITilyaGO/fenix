module SL
end

class SL::Product
  attr_accessor :id, :arn, :k1c, :multi, :raw, :sticker

  def initialize product
    @id = product
    @arn = CabiePio.get([:product, :archetype], product).data
    @k1c = CabiePio.get([:product, :k1c], product).data
    m = CabiePio.get([:product, :archetype_multi], product).data
    @multi = m.to_i if m
    @sticker = CabiePio.get([:products, :sticker], product).data.to_f
  end

  def save_links
    if @raw[:arn] != @arn
      CabiePio.set [:product, :archetype], @id, @raw[:arn]
      CabiePio.unset([:product, :archetype], @id) if @raw[:arn].empty?
    end
    if @raw[:k1c] != @k1c
      CabiePio.set [:product, :k1c], @id, @raw[:k1c]
      CabiePio.unset([:product, :k1c], @id) if @raw[:k1c].empty?
    end
    rmu = @raw[:multi].to_i
    if rmu > 1
      CabiePio.set([:product, :archetype_multi], @id, @raw[:multi]) unless rmu.eql?(@multi)
    else
      CabiePio.unset [:product, :archetype_multi], @id
    end

    sti = @raw[:sticker].to_f
    if sti > 0
      CabiePio.set [:products, :sticker], @id, @raw[:sticker] unless sti.eql?(@sticker)
    else
      CabiePio.unset [:products, :sticker], @id
    end
  end

end