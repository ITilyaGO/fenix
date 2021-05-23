Fenix::App.controllers :picupload do
  post :up, :with => :id do
    order = Order.find(params[:id])
    files = params[:files]
    files.each do |file|
      tempfile = file[:tempfile]

      kimage = KSM::OrderImage.born(order.id, file[:filename].downcase)
      kimage.fill(filename: file[:filename], type: file[:type], size: tempfile.size, merge: true)
      kimage.fill(created_at: Time.now, merge: true)
      # kimage.fill(filename: file[:filename], type: file[:type])
      kimage.save
      # korder = KSM::ImageChain.find order.id
      # stack = korder.exist? ? korder.body : []
      # stack << kimage.id
      # korder.body = stack
      # korder.save
      FileUtils.cp tempfile.path, pic_path(kimage.id)
      FileUtils.chmod 0777, pic_path(kimage.id)
    end
    redirect url(:orders, :edit, :id => order.id)
  end

  post :remove do
    order = Order.find(params[:id])
    kimage = KSM::OrderImage.find(params[:image])
    kimage.remove
    # korder = KSM::ImageChain.find order.id
    # stack = korder.exist? ? korder.body : []
    # stack.delete(kimage.id)
    # korder.body = stack
    # korder.save
    FileUtils.rm pic_path(kimage.id) rescue true

    redirect url(:orders, :edit, :id => order.id)
  end
end