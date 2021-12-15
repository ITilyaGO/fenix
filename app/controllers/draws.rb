Fenix::App.controllers :draws do
  get :index do
    @title = "Все тиражи"
    # @draws = KSM::Draw.all.sort_by{|a|a.sortname}.reverse

    @draws = kc_daydraws(Date.today) + kc_daydraws(Date.today - 1) + kc_daydraws(Date.today - 2)
    current = wonderbox(:draws_stack)
    @cdraws = KSM::Draw.find_all(current).sort_by{|a|a.sortname}.reverse
    @prday = (Date.today+1).strftime('%d.%m.%Y')

    render 'draws/index'
  end

  get :create do
    @title = "Создать тираж"
    @supermodel = KSM::Draw.new({})
    @supermodel.name = "#{(Date.today).strftime('%d.%m.%Y')}"
    # @plsn = draw_seed_get
    render 'draws/create'
  end

  post :create do
    form = params[:ksm_draw]
    form[:more] = nil if form[:more].empty?
    day = Date.strptime form[:name], '%d.%m.%Y'
    sni = form[:sns].to_i
    max = draw_seed_max(day)
    dumb = KSM::Draw.new(sn: sni, type: form[:type])
    daynumtk = draw_seed_taken?(day, dumb.common)
    sn = sni > 0 ? sni : draw_seed_for(day)
    if daynumtk
      flash.now[:warning] = "Duplicate Error: #{dumb.common}"
      return render 'draws/error'
    end
    @draw = KSM::Draw.nest day, sn
    @draw.fill **KSM::Draw.formize(form), merge: true
    @draw.save
    draws_stack_push @draw.id
    form[:orders]&.each do |fo|
      draw_and_order_set @draw.id, fo
    end
    redirect url(:draws, :index)
  end

  post :to_print, :provides => :json do
    day = Date.strptime params[:day], '%d.%m.%Y'
    fdraws = params[:draws].split(',')
    draws = KSM::Draw.find_all fdraws
    draws.each do |fdraw|
      fdraw.printed = day
      fdraw.save
    end
    draws_stack_pop fdraws

    [day, fdraws].to_json
  end

end