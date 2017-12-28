class SortController < ApplicationController
  skip_before_action :verify_authenticity_token

  def sort_data
    #curl --data "data=9,8,7,6" -X POST http://localhost:3000/test_sort_data

    data_params = params[:data].split(',').map(&:to_i)
    sorted_data = RemoteControl.spread_calc(data_params)
    render json: sorted_data.to_json, status: 200, content_type: "application/json"
  end
end
