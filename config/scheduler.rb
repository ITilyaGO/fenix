scheduler = Rufus::Scheduler.new(:frequency => 10)

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
end

scheduler.in '5s' do
  need = Order.where(:updated_at => 1.hours.ago..Time.now).count > 0
  from = ActiveRecord::Base.configurations[Padrino.env][:database]
  to = "#{Padrino.root}/db/fenix.#{Time.now.strftime("%y-%m-%d_%H")}.db"
  sqlbackup(from, to) if need
end