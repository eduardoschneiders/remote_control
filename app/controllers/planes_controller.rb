class PlanesController < ApplicationController
  def index
    @planes = Plane.all
  end

  def show
    @plane = Plane.find(params[:id])
  end

  def try_to_reserve
    if plane = Plane.find(params[:plane_id])
      booking = { plane_id: plane.id, plane_name: plane.name, seat_number: params[:seat_number]}
      RemoteControl.reserve_resource(booking)
      session[:booking] = booking

      render json: {}.to_json, status: 200, content_type: "application/json", location: '/testtt'
    else
      render json: {}.to_json, status: 500, content_type: "application/json", location: '/testtt'
    end
  end

  def signup
  end

  def reserved
    booking = session[:booking]
    RemoteControl.free_resource(booking)
    Plane.where(name: booking['plane_name']).first.reserve(booking['seat_number'])

    return redirect_to planes_path
  end

  private
end
