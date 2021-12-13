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
    helpers StatHelper
    helpers ArchetypeHelper
    helpers C1CHelper
    helpers HttpHelper

    helpers ThingsHelper
    helpers DrawsHelper
  end
end