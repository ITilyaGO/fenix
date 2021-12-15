module Fenix::App::DrawsHelper
  def draw_seed_for date = Date.today
    day = timeline_id date
    bo = wonderbox(:draws_seed) || {}
    seed = bo.fetch(day, 0) + 1
    bo[day] = seed
    wonderbox_set(:draws_seed, bo)
    seed
  end

  def draw_seed_get date = Date.today
    day = timeline_id date
    bo = wonderbox(:draws_seed) || {}
    bo.fetch(day, 0) + 1
  end

  def draw_seed_max date = Date.today
    day = timeline_id date
    bo = wonderbox(:draws_seed) || {}
    bo.fetch(day, 0)
  end

  def draw_seed_taken? date = Date.today, cn
    draws = kc_daydraws date
    draws.map(&:common).include? cn
  end

  def draw_order_id draw, order
    "#{draw}_#{order}"
  end

  def draw_order_unf draworder
    draworder.split('_').first
  end

  def draw_and_order_set draw, order
    CabiePio.set [:draw, :order], draw_order_id(draw, order), 1
  end

  def order_draws_for order
    old_need = CabiePio.query("p/draw/order>.*_#{order}", type: :regex).flat.keys.map{|d|draw_order_unf(d)}
  end

  def kc_daydraws day = Date.today
    KSM::Draw.allday timeline_id(day)
  end

  def draws_stack_push id
    bo = wonderbox(:draws_stack) || []
    bo << id
    wonderbox_set(:draws_stack, bo)
  end

  def draws_stack_pop ids
    bo = wonderbox(:draws_stack) || []
    bo = bo - [ids].flatten
    wonderbox_set(:draws_stack, bo)
  end
end