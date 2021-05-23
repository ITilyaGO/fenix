module Fenix::App::MigrateHelpers
  def sticker_history_005_up
    all = CabiePio.folder(:m, :order_lines, :sticker)
    all.each do |ol_sticker|
      next unless ol_sticker.key.public.include? '_'
      ol = ol_sticker.key.public.split('_').first
      next unless ol_sticker.key.public.split('_').last.size < 6
      timeline_id = ol_sticker.data[:t]
      CabiePio.set [:m, :order_lines, :sticker], "#{ol}_#{timeline_id}", ol_sticker.data
      CabiePio.unset [:m, :order_lines, :sticker], ol_sticker.key.public
    end
  end
end
