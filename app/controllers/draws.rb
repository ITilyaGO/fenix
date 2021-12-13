Fenix::App.controllers :draws do
  get :index do
    @title = "Все тиражи"
    @draws = KSM::Draw.all.sort_by{|a|a.sortname}.reverse
    render 'draws/index'
  end

  get :create do
    @title = "Создать тираж"
    @supermodel = KSM::Draw.new({})
    @supermodel.name = "#{(Date.today).strftime('%d.%m.%y')}"
    @plsn = draw_seed_get
    render 'draws/create'
  end

  post :create do
    form = params[:ksm_draw]
    form[:more] = nil if form[:more].empty?
    day = Date.strptime form[:name], '%d.%m.%y'
    sni = form[:sns].to_i
    max = draw_seed_max(day)
    sn = sni > 0 ? sni : draw_seed_for(day)
    unless sn > max
      flash.now[:warning] = 'Error'
      return render 'draws/error'
    end
    @draw = KSM::Draw.nest day, sn
    @draw.fill **KSM::Draw.formize(form), merge: true
    @draw.save
    form[:orders]&.each do |fo|
      draw_and_order_set @draw.id, fo
    end
    redirect url(:draws, :index)
  end

  
end