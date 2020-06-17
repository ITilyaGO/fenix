module Fenix::App::ClientsHelper

  KNOWN_TK = {
    :std => ['пэк', 'пэком', 'байкал'],
    :pecom => ['пэк!', 'только пэк'],
    :dellin => ['деловые линии', 'деловыми линиями', 'деловые'],
    :baikal => ['байкал!', 'только байкал'],
    :kit => ['кит'],
    :jde => ['желдор'],
    :nrg => ['энерги'],
    :novotrans => ['прогресс'],
    :mas => ['мас-хэндлинг', 'мас=хэндлинг', 'мас хендлинг'],
    :dpd => ['vipidi', 'dpd', 'дпд'], # lol vipidi
    :cdek => ['сдэк', 'сдек'],
    :steil => ['стэйл', 'стеил', 'стейл'],
    :artec => ['артэк'],
    :aviamir => ['авиамир'],
    :azimut => ['азимут'],
    :ratek => ['ратэк'],
    :rail => ['рейл'],
    :parnas => ['парнас']
  }

  def transport_valid?(tr)
    KNOWN_TK.keys.include? tr
  end

  def transport_list
    KNOWN_TK.keys
  end

  def guess_transport(client, save: false)
    ship = client.shipping_company&.downcase
    note = client.comment&.downcase

    test_array = KNOWN_TK.map{|k,v|v.map{|e| {e=>k}}}.flatten.reverse.reduce(Hash.new, :merge)

    found = []
    found2 = []
    test_array.each do |test_value, id|
      f = ship&.include? test_value
      found << id if f
    end
    test_array.each do |test_value, id|
      f = note&.include? test_value
      found2 << id if f
    end

    choice = found + found2
    choice.delete(:std) if choice.uniq.size > 1
    if choice && save
      CabiePio.set [:m, :clients, :transport], client.id, choice.first
    end
    { id: client.id, v: choice&.first, f1: found, f2: found2 }
  end

  def sql_avail_shipping
    # test_array = KNOWN_TK.map{|k,v|v.map{|e| {e=>k}}}.flatten.reverse.reduce(Hash.new, :merge)
    # Client.pluck(:shipping_company).compact.map(&:downcase).uniq
    # Client.pluck(:comment).compact.map(&:downcase).uniq

    o = Client.all.map do |cl|
      guess = guess_transport(cl)
      "#{guess[:id]} #{guess[:f1].join(',')} - #{guess[:f2].join(',')} ; #{cl.shipping_company} #{cl.comment}"
    end

    YAML.dump o
  end


end
