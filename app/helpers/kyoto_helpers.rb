module Fenix::App::KyotoHelpers
  def sec(&block)
    time1 = Time.new
    yield block
    Time.new - time1
  end

  def notice_for_time(time)
    string = time < 1 ? "#{(time*1000).ceil} ms" : "#{time.ceil 3} sec"
    "Time taken: #{string}"
  end

  def a_towns(order_ids, client_ids)
    @kc_orders = CabiePio.all_keys(order_ids, folder: [:orders, :towns]).flat
    @kc_delivery = CabiePio.all_keys(order_ids, folder: [:orders, :delivery_towns]).flat
    @kc_hometowns = CabiePio.all_keys(client_ids, folder: [:clients, :hometowns]).flat
    @kc_client_delivery = CabiePio.all_keys(client_ids, folder: [:clients, :delivery_towns]).flat
    codes = @kc_orders.values.uniq + @kc_delivery.values.uniq + @kc_client_delivery.values.uniq + @kc_hometowns.values.uniq
    @kc_towns = KatoAPI.batch(codes)
    true
  end

  def a_managers(order_ids, client_ids)
    @kc_orders = CabiePio.all_keys(order_ids, folder: [:orders, :towns]).flat
    @kc_delivery = CabiePio.all_keys(order_ids, folder: [:orders, :delivery_towns]).flat
    @kc_hometowns = CabiePio.all_keys(client_ids, folder: [:clients, :hometowns]).flat
    @kc_client_delivery = CabiePio.all_keys(client_ids, folder: [:clients, :delivery_towns]).flat
    codes = @kc_orders.values.uniq + @kc_delivery.values.uniq + @kc_client_delivery.values.uniq + @kc_hometowns.values.uniq
    @kc_towns = KatoAPI.batch(codes)
    kc_town_managers = CabiePio.folder(:towns, :managers).flat
    @managers = Manager.all.pluck(:id, :name).to_h
    @kc_managers = codes.map do |code|
      hier = Kato::Hier.for(code).codes
      manager = hier.detect{|c| kc_town_managers[c]}
      [code, kc_town_managers[manager]]
    end.to_h.compact
  end

  def wonderbox(key, prop=nil)
    return all_wonderbox.fetch(key.to_s, nil) unless prop
    all_wonderbox.dig(key.to_s, prop)
  end

  def wonderbox_set(key, value)
    CabiePio.set [:m, :wonderbox], key, value
    @wonderbox = nil
    all_wonderbox
  end

  def all_wonderbox
    @wonderbox ||= CabiePio.folder(:m, :wonderbox).flat
  end
end