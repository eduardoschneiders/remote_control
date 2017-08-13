class Plane < ApplicationRecord
  serialize :seats, Array
  serialize :reserved_seats, Array

  def reserved?(seat)
    reserved_seats.include?(seat.to_s)
  end

  def reserve(seat)
    reserved_seats << seat
    save
  end
end
