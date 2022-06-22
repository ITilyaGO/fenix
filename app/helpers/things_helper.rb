module Fenix::App::ThingsHelper
  def thing_to_top id
    bo = wonderbox(:things_by_date)
    bo.unshift
    bo.delete id
    bo << id
    wonderbox_set(:things_by_date, bo.take(100))
  end

  def thing_seed_from cat
    bo = wonderbox(:things_seed) || {}
    seed = bo.fetch(cat, 0) + 1
    bo[cat] = seed
    wonderbox_set(:things_seed, bo)
    seed
  end

  def thing_glob_seed
    bo = wonderbox(:things_glob_seed) || {}
    seed = bo.fetch(:seed, 0) + 1
    bo[:seed] = seed
    wonderbox_set(:things_glob_seed, bo)
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

  def sect_seed_root
    seed = wonderbox(:sections, :seed) || 0
    seed += 1
    wonderbox_set(:sections, { seed: seed })
    seed
  end

  def update_autodic thing
    ap = KSM::Dic.find(:autoproduct)
    ap.push(thing.name, and_save: true) if thing.name =~ /w+/
    al = KSM::Dic.find(:autolook)
    al.push(thing.look, and_save: true) if thing.look =~ /w+/
  end
end