class SL::Category < KSM::Category
  def parent
    category_id || section_id
  end
end

class SL::Section < KSM::Section
  attr_accessor :parent, :wfindex
  def wfindex
    (@wfindex || 0).to_s
  end
end

class SL::Thing < Product
  def parent
    category_id
  end
end