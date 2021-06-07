class DoppelK1c < Cabie::Doppel
  LAYER = CabieK1c
end

module KSM1C
  # Kyoto Super Models 1c
end

class KSM1C::Cat < DoppelK1c
  PFX = :cat

  PROPS = [:kind, :ref, :parent, :xml]
  attr_accessor *PROPS
  
  def noko
    Nokogiri::XML @xml
  end

  def spath(name)
    noko.xpath "//#{name}"
  end

  def path(name)
    noko.xpath name
  end

  def at_path(name)
    spath(name).children.first&.content
  end
end