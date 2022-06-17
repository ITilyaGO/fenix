class KSM::Order < Doppel
  PFX = :order

  PROPS = [:parts, :lines, :client_id, :priority, :delivery, :online_id, :created_at, :updated_at]
  attr_accessor *PROPS

  # attr_accessor :parent

  def initialize opts
    super
    @lines ||= []
    @parts ||= []
    self
  end

  class << self

  end
end
