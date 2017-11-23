class Plane
  attr_accessor :id, :name, :seats, :reserved_seats, :from, :to

  MODEL_NAME = 'planes'

  def initialize(id:, name:, seats:, reserved_seats:, from:, to:)
    @id = id
    @name = name
    @seats = seats
    @reserved_seats = reserved_seats
    @from = from
    @to = to
  end

  def self.all
    # @all ||= begin
       response = firebase.get(MODEL_NAME)
       response.body.map do |id, properties|
         data = properties.merge(id: id).symbolize_keys
         Plane.new(data)
       end
     # end
  end

  def self.where(query)
    all.select do |plane|
      query.all? do |property, value|
        plane.send(property) == value
      end
    end
  end

  def self.find(id)
    where(id: id).first
  end

  def self.create(params)
    params[:seats] = params[:seats].to_i.times.map { |i| i }

    plane = new(params)
    plane.send(:save)
  end

  def reserved?(seat)
    reserved_seats.include?(seat.to_s)
  end

  def reserve(seat)
    reserved_seats << seat
    save
  end

  def to_hash
    property_names = self.instance_variables.map do |prop|
      prop.to_s.gsub('@', '')
    end.reject do |prop|
      prop == 'id'
    end

    property_names.inject({}) do |acc, prop|
      acc[prop] = self.send(prop); acc
    end
  end

  private

  def firebase
    Plane.firebase
  end

  def self.firebase
    base_uri = 'https://remotecontrol-35696.firebaseio.com/'

    firebase = Firebase::Client.new(base_uri)
  end

  def save
    if self.id.present?
      firebase.update(MODEL_NAME, "#{self.id}" => self.to_hash)
    else
      firebase.push(MODEL_NAME, self.to_hash)
    end
  end
end
