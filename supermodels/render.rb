class KSM::Render < Doppel
  PFX = :render
  PROPS = [:contents, :updated_at]
  attr_accessor *PROPS

  class << self
    def nest *args
      @args = args
      e = super()
      e.fill(updated_at: Time.now, merge: true)
      e
    end

    def find *args
      @args = args
      super new_id
    end

    def new_id
      @args.join '_'
    end
  end
end