class KSM::OrderShip < Doppel
  PFX = :order_ship

  PROPS = %i[transport transport_note notify_adr notify_note notifier]
  attr_accessor *PROPS

  def notifier? kind
    notifier == kind
  end

  def nocontent?
    [@notify_adr, @notify_note].compact.join.empty?
  end

  def save
    is_mail = notify_adr =~ /@/
    if notify_adr
      @notify_adr = @notify_adr.gsub /\s/, ''
      @notifier = is_mail ? :email : :wa
    end
    super
  end

  class << self
    def schema
      {
        transport: [:to_sym],
        notifier: [:to_sym]
      }
    end
  end
end
