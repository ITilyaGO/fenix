module Fenix
  class App < Padrino::Application
    use ConnectionPoolManagement
    register Padrino::Mailer
    register Padrino::Helpers
    register Padrino::Admin::AccessControl

    ##
    # Caching support.
    #
    # register Padrino::Cache
    # enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache.new(:LRUHash) # Keeps cached values in memory
    # set :cache, Padrino::Cache.new(:Memcached) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Memcached, '127.0.0.1:11211', :exception_retry_limit => 1)
    # set :cache, Padrino::Cache.new(:Memcached, :backend => memcached_or_dalli_instance)
    # set :cache, Padrino::Cache.new(:Redis) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Redis, :host => '127.0.0.1', :port => 6379, :db => 0)
    # set :cache, Padrino::Cache.new(:Redis, :backend => redis_instance)
    # set :cache, Padrino::Cache.new(:Mongo) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Mongo, :backend => mongo_client_instance)
    # set :cache, Padrino::Cache.new(:File, :dir => Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options.
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_apps_root_path/locale)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    set :admin_model, 'Account'
    set :login_page,  '/sessions/new'

    enable :sessions
    set :sessions, key: 'fenix.session', secret: '571fc3d7df5SFgkepw6jfi5e976aedbaf7feb410739DJR*c3b571fc3d7df5I', expire_after: 60*60*24

    disable :store_location

    set :princebin, 'fuckedprince'
    set :princepath, './vendor/prince/bin/fuckedprince'
    set :princelog, Padrino.root('log', 'prince.log')

    access_control.roles_for :any do |role|
      role.protect '/'
      role.allow   '/sessions'
    end

    access_control.roles_for :admin do |role|
      role.project_module :accounts, '/accounts'
      role.project_module :online, '/online'
      role.project_module :orders, '/orders'
      role.project_module :orders_create, '/orders/fullempty'
      role.project_module :orders_draft, '/orders/draft'
      role.project_module :orders_infact, '/orders/infact'
      role.project_module :orders_stickers, '/orders/stickers'
      role.project_module :picupload, '/picupload'
      role.project_module :categories, '/categories'
      role.project_module :products, '/products'
      role.project_module :sections, '/sections'
      role.project_module :places, '/places'
      role.project_module :editors, '/clients'
      role.project_module :prefs, '/prefs'
      role.project_module :kyoto, '/kyoto'
      role.project_module :health, '/health'
    end

    access_control.roles_for :editor do |role|
      role.project_module :orders, '/orders'
      role.project_module :orders_create, '/orders/fullempty'
      role.project_module :orders_draft, '/orders/draft'
      role.project_module :categories, '/categories'
      role.project_module :products, '/products'
      role.project_module :places, '/places'
      role.project_module :editors, '/clients'
    end

    access_control.roles_for :user do |role|
      role.project_module :orders, '/orders'
      role.project_module :orders_infact, '/orders/infact'
      role.project_module :categories, '/categories'
      role.project_module :products, '/products'
      role.project_module :places, '/places'
    end

    access_control.roles_for :stickerman do |role|
      role.project_module :orders, '/orders'
      role.project_module :orders_stickers, '/orders/stickers'
      role.project_module :categories, '/categories'
      role.project_module :products, '/products'
      role.project_module :places, '/places'
    end

    [:sectioner, :limsectioner, :director, :manager, :supplier].each do |r|
      access_control.roles_for r do |role|
        role.project_module :orders, '/orders'
        role.project_module :orders_infact, '/orders/infact'
        role.project_module :categories, '/categories'
        role.project_module :products, '/products'
        role.project_module :places, '/places'
        role.project_module :editors, '/clients'
      end
    end

    ##
    # You can configure for a specified environment like:
    #
    #   configure :development do
    #     set :foo, :bar
    #     disable :asset_stamp # no asset timestamping for dev
    #   end
    #

    ##
    # You can manage errors like:
    #

    error 404 do
      render 'errors/404', :layout => :basic 
    end
    
    #
    #   error 500 do
    #     render 'errors/500'
    #   end
    #

    APP_NAME = 'pio'
    if File.file? Padrino.root('version')
      ver, date = File.read(Padrino.root('version')).lines.map(&:chomp)
    else
      ver, date = [:DEV, Time.new.to_s]
    end
    APP_VERSION = ver
    APP_MAJOR = ver.split('.').shift(2).join('.') if ver.respond_to? :split
    APP_MAJOR ||= APP_VERSION
    APP_DATE = DateTime.parse(date)

  end
end
