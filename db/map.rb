module Cabie::Structure
  KEYMAP = {
    [:p, :clients, :hometowns] => nil,
    [:p, :clients, :delivery_towns] => nil,
    [:p, :orders, :towns] => nil,
    [:p, :orders, :delivery_towns] => nil,
    [:p, :orders, :timeline] => nil,
    [:p, :orders, :stickers_amount] => nil,
    [:p, :products, :sticker] => nil,
    [:p, :timeline, :order] => nil,
    [:p, :sticker, :order] => nil,
    [:p, :sticker, :order_progress] => nil,
    [:p, :complexity, :product] => nil,
    [:p, :complexity, :category] => nil,
    [:p, :complexity, :order] => nil,
    [:p, :towns, :managers] => nil,
    [:p, :towns, :migrate, :known] => nil,
    [:p, :towns, :migrate, :unknown] => nil,
    [:p, :towns, :migrate, :old] => nil,
    [:m, :clients, :transport] => nil,
    [:m, :order_lines, :sticker] => nil,
    [:m, :sticker, :order_history] => nil,
    [:m, :towns, :migrate, :debug] => nil,
    [:m, :dic, :transport] => nil,
    [:m, :managers, :geo_poss] => nil,
    [:m, :wonderbox] => nil
  }.freeze
  MAPTREE = {
    :root => [
      p: [
        :clients => [:hometowns, :delivery_towns],
        :orders => [:towns, :delivery_towns, :timeline, :stickers_amount],
        :products => [:sticker],
        :timeline => [:order],
        :sticker => [:order, :order_progress],
        :complexity => [:product, :category, :order],
        :towns => [:managers, :migrate]
      ],
      m: [
        :clients => [:transport],
        :order_lines => [:sticker],
        :sticker => [:order_history],
        :dic => [:transport],
        :managers => [:geo_poss],
        :wonderbox => []
      ]
    ]
  }.freeze
end