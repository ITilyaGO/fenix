module Front
  class App < Padrino::Application
    register Padrino::Helpers

    disable :protect_from_csrf
    disable :store_location

    error 404 do
      render 'errors/404', :layout => :basic
    end
  end
end
