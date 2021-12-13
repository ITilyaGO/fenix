module Cabie::Structure
  KEYMAP = {
    [:p, :anewdate, :order] => nil,
    [:p, :clients, :hometowns] => nil,
    [:p, :clients, :delivery_towns] => nil,
    [:p, :orders, :anewdate] => nil,
    [:p, :orders, :cash] => nil,
    [:p, :orders, :towns] => nil,
    [:p, :orders, :delivery_towns] => nil,
    [:p, :orders, :stickday] => nil,
    [:p, :orders, :timeline] => nil,
    [:p, :orders, :timeline_blink] => nil,
    [:p, :orders, :stickers_amount] => nil,
    [:p, :k1c, :product] => nil,
    [:p, :product, :k1c] => nil,
    [:p, :product, :archetype] => nil,
    [:p, :product, :archetype_multi] => nil,
    [:p, :products, :sticker] => nil,
    [:p, :timeline, :order] => nil,
    [:p, :sticker, :order] => nil,
    [:p, :sticker, :order_glass] => nil,
    [:p, :sticker, :order_progress] => nil,
    [:p, :need, :archetype] => nil,
    [:p, :need, :product] => nil,
    [:p, :need, :order] => nil,
    [:p, :stickday, :order] => nil,
    [:p, :stock, :archetype] => nil,
    [:p, :stock, :product] => nil,
    # [:p, :stock, :order, :a] => nil,
    # [:p, :stock, :order, :n] => nil,
    [:p, :stock, :common, :a] => nil,
    # [:p, :stock, :common, :n] => nil,
    [:p, :complexity, :product] => nil,
    [:p, :complexity, :category] => nil,
    [:p, :complexity, :order] => nil,
    [:p, :towns, :managers] => nil,
    [:p, :towns, :migrate, :known] => nil,
    [:p, :towns, :migrate, :unknown] => nil,
    [:p, :towns, :migrate, :old] => nil,
    [:m, :archetype, :cde] => nil,
    [:m, :clients, :transport] => nil,
    [:m, :order_lines, :sticker] => nil,
    [:m, :order_lines, :sticker_sum] => nil,
    [:m, :order_image, :cde] => nil,
    [:m, :sticker, :order_history] => nil,
    [:m, :towns, :migrate, :debug] => nil,
    [:m, :dic, :transport] => nil,
    [:m, :managers, :geo_poss] => nil,
    [:m, :wonderbox] => nil,
    [:i, :orders, :sticker_date] => nil
  }.freeze
  MAPTREE = {
    :root => [
      p: [
        :clients => [:hometowns, :delivery_towns],
        :orders => [:cash, :towns, :delivery_towns, :stickday, :timeline, :timeline_blink, :stickers_amount],
        :k1c => [:product],
        :product => [:k1c, :archetype, :archetype_multi],
        :products => [:sticker],
        :timeline => [:order],
        :stickday => [:order],
        :sticker => [:order, :order_glass, :order_progress],
        :stock => [:archetype, :product, :common],
        :need => [:archetype, :product, :order],
        :complexity => [:product, :category, :order],
        :towns => [:managers, :migrate]
      ],
      m: [
        :archetype => [],
        :clients => [:transport],
        :order_lines => [:sticker],
        :order_image => [],
        :sticker => [:order_history],
        :dic => [:transport],
        :managers => [:geo_poss],
        :wonderbox => []
      ],
      i: [
        :orders => [:sticker_date]
      ]
    ]
  }.freeze
end