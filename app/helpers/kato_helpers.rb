module Fenix::App::KatoHelpers
  def places_global(q, limit)
    qup = q.upcase
    is_code = Kato.valid? qup 
    is_kque = Kato.valid? Kato.drill(qup, :region)
    if is_code
      places = [qup]
    elsif is_kque
      r = Kato.drill(qup, :region)
      places = KatoAPI.search([:m, :twn], qup, max:limit, index:false).flat.keys
      places += KatoAPI.search([:m, :all], qup, max:limit, index:false).flat.keys if places.size < limit
    else
      places = KatoAPI.search(:short, q, max:limit).flat.values
      places += KatoAPI.search(:full, q, max:limit).flat.values if places.size < limit
    end
    data = KatoAPI.batch(places)

    list = data.map{|k,v| { id: k, name: v.model.name }}.reject{|h|h[:name].nil?}
    list
  end
end

