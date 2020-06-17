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
end if Padrino.env == :production

scheduler.cron '10 1 * * *' do
  from = ActiveRecord::Base.configurations[Padrino.env][:database]
  to = "#{Padrino.root}/db/fenix.daily.db"
  sqlbackup(from, to)

  ALL_CABIES.slice(:pio).keys.each do |c|
    Cabie.wire(c).backup
  end
end if Padrino.env == :production

# scheduler.cron '25 2 * * *' do
scheduler.in '0s' do
  if OrderJobs.wonderbox(:complexity_job)
    OrderJobs.complexity_job(all: true)
  end
  if OrderJobs.wonderbox(:sticker_job)
    OrderJobs.sticker_job(all: true)
  end
end

$background = Rufus::Scheduler.new(:frequency => 60)
