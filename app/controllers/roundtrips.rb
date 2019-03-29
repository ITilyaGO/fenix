Fenix::App.controllers :roundtrips do
  get :index do
    @title = "График поездок"
    @roundtrips = Roundtrip.where('start_at > ?', Date.today - 1.month).order(:start_at => :desc)
    render 'roundtrips/index'
  end

  put :new do
    valid_date = Date.parse(params[:start]) rescue nil
    if valid_date && (Place.exists? params[:place_id])
      Roundtrip.create({ :start_at => params[:start], :place_id => params[:place_id] })
      redirect(url(:roundtrips, :index))
    else
      flash[:error] = 'Упс. Произошла ошибка и мы не смогли это сохранить.'
    end
    redirect(url(:roundtrips, :index))
  end

  get :destroy, :with => :id do
    trip = Roundtrip.find(params[:id])
    if trip
      if current_account.is_admin? && trip.destroy
        flash[:success] = pat(:delete_success, :model => 'Order', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'order')
      end
      redirect url(:roundtrips, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end
end