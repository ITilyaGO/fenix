module Fenix::App::ThingsHelper
  def thing_to_top id
    bo = wonderbox(:things_by_date)
    bo.unshift
    bo.delete id
    bo << id
    wonderbox_set(:things_by_date, bo)
  end

  def thing_seed_from cat
    bo = wonderbox(:things_seed) || {}
    seed = bo.fetch(cat, 0) + 1
    bo[cat] = seed
    wonderbox_set(:things_seed, bo)
    seed
  end

  def cate_seed_from topcat = :root
    topcat ||= :root
    bo = wonderbox(:cat_seed) || {}
    seed = bo.fetch(topcat, 0) + 1
    bo[topcat] = seed
    wonderbox_set(:cat_seed, bo)
    seed
  end
end