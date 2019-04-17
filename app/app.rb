module Fenix
  class App < Padrino::Application
    use ConnectionPoolManagement
    register Padrino::Mailer
    register Padrino::Helpers
    register Padrino::Admin::AccessControl
    enable :sessions

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

    set :sessions, key: 'fenix.session', secret: '571fc3d7df5SFgkepw6jfi5e976aedbaf7feb410739DJR*c3b571fc3d7df5I', expire_after: 60*60*24

    disable :store_location

    set :princebin, './vendor/prince/bin/fuckedprince'
    set :princelog, './log/prince.log'

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
      role.project_module :categories, '/categories'
      role.project_module :products, '/products'
      role.project_module :places, '/places'
      role.project_module :editors, '/clients'
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
      role.project_module :categories, '/categories'
      role.project_module :products, '/products'
      role.project_module :places, '/places'
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
    #   error 404 do
    #     render 'errors/404'
    #   end
    #
    #   error 500 do
    #     render 'errors/500'
    #   end
    #
  end
end
