class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def blocking
    MyTest.set_as_blocking({ passagem: { target: 'taquara' }})
    render plain: 'BLOCKED'
  end

  def no_blocking
    render plain: 'NO BLOCKED'
  end
end
