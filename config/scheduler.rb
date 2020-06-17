scheduler = Rufus::Scheduler.new(:frequency => 60)

def sqlbackup(from, to)
  sdb = SQLite3::Database.new(from)
  ddb = SQLite3::Database.new(to)

  b = SQLite3::Backup.new(ddb, 'main', sdb, 'main')
  begin
    b.step(1)
  end while b.remaining > 0
  b.finish
end

scheduler.cron '0 0 * * 6' do
  FileUtils.cp "#{Padrino.root}/db/fenix.daily.db", "#{Padrino.root}/db/fenix.weekly.db"
end

scheduler.cron '5 0 * * *' do
  from = ActiveRecord::Base.configurations[Padrino.env][:database]
  to = "#{Padrino.root}/db/fenix.daily.db"
  sqlbackup(from, to)

  ALL_CABIES.slice(:pio).keys.each do |c|
    Cabie.wire(c).backup
  end
end if Padrino.env == :production
end
