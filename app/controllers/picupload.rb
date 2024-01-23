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

  post :things, :with => :id do
    product = Product.find(params[:id])
    file = params[:file]
    tempfile = file[:tempfile]

    is = ImageSize.path tempfile.path
    good = is.format && is.size.uniq.one? && (600..816) === is.w
    if not good
      FileUtils.rm tempfile.path
      flash[:error] = t 'error.bad_file'
      flash[:bad_file] = true
      redirect url(:things, :edit, :id => product.id)
    end

    product.picfile = Secure.uuid.gsub(/-/, '')

    make_product_pic_path product.picname
    FileUtils.cp tempfile.path, product_pic_file(product.picname, :r)
    FileUtils.cp product_pic_file(product.picname, :r), product_pic_file(product.picname, :m)
    FileUtils.touch product_pic_file(product.picname, :t)
    FileUtils.chmod 0777, [product_pic_file(product.picname), product_pic_file(product.picname, :r)]
    opti_pic(product.picname)
    product.save

    redirect url(:things, :edit, :id => product.id)
  end
end