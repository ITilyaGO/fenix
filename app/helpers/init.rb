module Fenix
  class App
    IDSEP = '_'.freeze

    helpers KatoHelpers
    helpers KyotoHelpers
    helpers ProductsHelper
    helpers ClientsHelper
    helpers OrdersHelper
    helpers TimelineHelper
    helpers StickerHelper
  end
end