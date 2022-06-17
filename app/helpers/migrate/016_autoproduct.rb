module Fenix::App::MigrateHelpers
  def m016_autoproduct_up force: nil
    
    ap = KSM::Dic.find(:autoproduct)
    # ap.contents = nil
    Product.all.each do |p|
      ap.push p.name
    end
    ap.save

    al = KSM::Dic.find(:autolook)
    al.contents = nil
    Product.all.each do |p|
      al.push p.name.split.last.gsub(/[\"\(\)]/,'')
    end
    al.save
  end
end