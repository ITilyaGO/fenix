Fenix::App.controllers :prefs do

  #TODO: refactor to post requests!!!

  get :ktimeline do
    # @ktm = CabiePio.query('p/timeline/order>1904', :type => :regex).inspect
    @ktm = CabiePio.all([:timeline, :order], ['1903']).flat
    @ktm = @ktm.merge CabiePio.all([:timeline, :order], ['1904']).flat

    @time = Timeline.all
    render "list/timeline"
  end

  get :complex_migrate, :map => 'list/complex/migrate' do
    @time = Order.all
    CabiePio.clear(:complexity, :order)
    @time.each do |t|
      CabiePio.set [:complexity, :order], t.id, calc_complexity_for(t)
    end
    render "list/complex"
  end

  get :box, :map => 'list/box' do
    # wonderbox_set(:complex_level, 512)
    # wonderbox_set(:complexity, { level: 256, limit: 512, unbusy: 6 })
    render "list/complex"
  end
  get :page do
    @title = t 'tit.prefs.page'
    render 'prefs/page'
  end

  get :levels do
    @title = t 'tit.prefs.page'
    render 'prefs/levels'
  end

  put :levels do
    wonderbox_set(:complexity, params[:complexity].transform_values(&:to_i))
    wonderbox_set(:stickday_threshold, params[:stickday_threshold].transform_values(&:to_i))

    render 'prefs/levels'
  end

end