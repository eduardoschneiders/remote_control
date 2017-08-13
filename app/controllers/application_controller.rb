class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from BlockedResource do
    render json: {msg: 'Resource already reserved'}, status: 400, content_type: "json/text"
  end

  def block
    RemoteControl.reserve_resource({ plain: params[:plain], seat: params[:seat]})
    render plain: 'Resource Reserved'
  end

  def unblock
    RemoteControl.free_resource({ plain: params[:plain], seat: params[:seat]})
    render plain: 'Resource not reserved anymore'
  end

  private

  def blockd_resource
    render json: {msg: 'Resource already reserved'}, status: 400, content_type: "json/text"
  end
end