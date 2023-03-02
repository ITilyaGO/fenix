class Doppel < Cabie::Doppel
  LAYER = CabiePio
  FPROPS = nil

  def serializable_hash
    to_h
  end

  def errors
    {}
  end

  def formiz *args
    fill self.class.formize(*args).merge(merge: true)
  end

  def clear_formize form
    (@klass::FPROPS||@klass::PROPS).each do |prop|
      form[prop] = nil if pe = form[prop]&.empty?
      instance_variable_set("@#{prop}", nil) if pe
    end
    formiz form
  end
end

class Supermodel
  # ActiveRecord replacement for admin
end

module KSM
  # Kyoto Super Models
end
