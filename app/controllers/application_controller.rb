class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def blocking
    RemoteControl.reserve_resource({ plain: params[:plain], seat: params[:seat]})
    render plain: 'BLOCKED'
  end

  def no_blocking
    render plain: 'NO BLOCKED'
  end
end
