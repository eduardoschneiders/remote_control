class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from BlockedResource do
    render json: {msg: 'Resource already reserved'}, status: 403, content_type: "application/json"
  end
end
