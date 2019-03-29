class Online::Order < Online::Base
  self.table_name = 'orders'
  belongs_to :account
  has_many :order_lines
  
  def self.status_name(status)
    case status
    when 0
      "Unkown"
    when 1
      "Новый"
    when 2
      "Подтвержден"
    when 3
      "Отгружен"
    else
      "Empty"
    end
  end
  
  def self.iq(id)
    a = id ^ 23081
    v = a.to_s
    if v.size < 2
      v
    else
      v2 = v.chars[1]
      vl = v.chars.last
      v[1] = vl
      v[v.chars.length - 1] = v2
      
      g = "%s%s" % [v[0], v[1..v.length].reverse]
      g
      # "%s%s" % [Random.new.rand(1..9), v]
    end
  end
  
  def self.deiq(id)
    if id.size < 2
      v = id
    else
      g = "%s%s" % [id[0], id[1..id.length].reverse]
      id = g
      v2 = id.chars[1]
      vl = id.chars.last
      id[1] = vl
      id[id.chars.length - 1] = v2
      v = id
    end
    a = v.to_i ^ 23081
    a
  end
  
  def self.shift_32 x, shift_amount
    shift_amount &= 0x1F
    x <<= shift_amount
    x &= 0xFFFFFFFF
    
    if (x & (1<<31)).zero?
     x
    else
     x - 2**32
    end
  end
end
