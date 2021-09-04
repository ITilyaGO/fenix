class CabieAssist
  def self.focus(path, list)
    out = []
    list.each do |key|
      out << CabiePio.all(path, key).flat.keys
    end
    out.flatten
  end
end