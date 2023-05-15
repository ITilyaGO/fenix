module Fenix::App::PictureHelper
  def picsrc(product, size = :m)
    ksm = Product.find(product)
    a = ksm.picname
    imgs = %w_ is what your get _
    return nil unless a
    # return "/images/#{imgs.sample}.jpeg" unless a
    product_pic_src a, ksm.ts.to_i, size
  end

  def product_pic_src(img, ts, mode = :m)
    "/images/p/#{img[0..1]}#{(mode if mode)}/#{img}?#{ts}"
  end

  def product_pic_file(img, mode = :m)
    product_pic_path(img, mode) + "/#{img}"
  end

  def product_pic_path(img, mode = :m)
    "#{Padrino.root}/public/images/p/#{img[0..1]}#{(mode if mode)}"
  end

  def make_product_pic_path(img)
    FileUtils.makedirs product_pic_path(img)
    FileUtils.makedirs product_pic_path(img, :r)
    FileUtils.makedirs product_pic_path(img, :m)
    FileUtils.makedirs product_pic_path(img, :t)
  end

  def opti_pic(img)
    im = {}
    im[:large] = product_pic_file(img, :r)
    im[:med] = product_pic_file(img, :m)
    im[:tiny] = product_pic_file(img, :t)
    im[:bmp_med] = product_pic_file(img, :m) + '.bmp'
    im[:bmp_tiny] = product_pic_file(img, :t) + '.bmp'
    im[:j_large] = product_pic_file(img, :r) + '.jpeg'
    FileUtils.touch im.values
    im = im.transform_values do |image|
      image = File.new image
    end
    large_image, med_image, tiny_image, bmp_med_image, bmp_tiny_image, j_large_image = im.values

    Mozjpeg.compress large_image, j_large_image, arguments: '-quality 95 -quant-table 2 -notrellis'
    Mozjpeg.scale j_large_image, bmp_med_image
    Mozjpeg.scale j_large_image, bmp_tiny_image, arguments: '-scale 1/8'
    Mozjpeg.compress bmp_tiny_image, tiny_image, arguments: '-quality 95 -quant-table 2 -notrellis'
    Mozjpeg.compress bmp_med_image, med_image, arguments: '-quality 95 -quant-table 2 -notrellis'

    FileUtils.rm [bmp_med_image, bmp_tiny_image]
  end
end
