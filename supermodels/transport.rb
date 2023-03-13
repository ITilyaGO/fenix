class KSM::Transport < Doppel
  PFX = :dic
  ENT_FOLDER = :transport

  PROPS = [:name]
  attr_accessor *PROPS

  def opttag
    [name||id, id]
  end
end