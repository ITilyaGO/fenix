module Fenix::App::SyncHelper
  def resync
    Product.global.each do |product|
      product.stompsync
    end
    KSM::Category.all.each do |cat|
      cat.stompsync
    end
  end

  def resync_cat
    KSM::Category.all.each do |cat|
      cat.stompsync
    end
  end
end

module SyncAssist
  extend Fenix::App::SyncHelper
end