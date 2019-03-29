Fenix::App.controllers :invoices do
  get :torg12, :with => :id do
    @title = pat(:edit_title, :model => "order #{params[:id]}")
    @order = Order.includes(:order_lines).find(params[:id])
    
    if @order
      render 'invoices/torg12', :layout => false
    else
      flash[:warning] = pat(:create_error, :model => 'order', :id => "#{params[:id]}")
      halt 404
    end
  end
end