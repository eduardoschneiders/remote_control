class AdminController < ApplicationController
  def show
  end

  def create
    data = plane_params.merge(
      reserved_seats: [plane_params[:seats].to_i + 1],
      id: nil)

    Plane.create(data.to_h.symbolize_keys)
    redirect_to root_path
  end

  private

  def plane_params
    params.require(:plane).permit([:name, :seats, :from, :to])
  end
end
