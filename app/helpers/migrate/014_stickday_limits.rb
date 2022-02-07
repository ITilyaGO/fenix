module Fenix::App::MigrateHelpers
  def stickday_limits_014_up force: nil
    wonderbox_set :stadie_grade, %i[01 02 03 04 05 06 07 08 09 0a 0b 0c]
    wonderbox_set :stadie_still, :'08'
    wonderbox_set :stickday_gather, 100
    wonderbox_set :stickday_limit, 10000
  end
end