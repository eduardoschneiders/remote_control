class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def index

    MyTest.set_as_blocking
    request.env['TEST'] = :foo
    render plain: 'OK'
  end
end
