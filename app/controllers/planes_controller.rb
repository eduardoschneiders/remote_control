class PlanesController < ApplicationController
  def index
    @planes = Plane.all
  end

  def try_to_reserve
    booking = { plane_name: params[:plane_name], seat_number: params[:seat_number]}
    RemoteControl.reserve_resource(booking)
    session[:booking] = booking
    redirect_to signup_path
  end

  def signup
  end

  def reserved
    booking = session.delete(:booking)
    RemoteControl.free_resource(booking)
    Plane.where(name: booking['plane_name']).first.reserve(booking['seat_number'])

    render html: "Seat #{booking['seat_number']} on plane #{booking['plane_name']} reserved #{view_context.link_to 'voltar', planes_path}".html_safe
  end

  private
end
