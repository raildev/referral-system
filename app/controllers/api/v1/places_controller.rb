module Api::V1
  class PlacesController < ActionController::Base
    def create
      parent = Place.find_by_code(params["Parent_code"])
      place = Place.find_by_code(params["Code"]) || Place.new

      place.name = params["Name"] if params["Name"]
      place.name_kh = params["Name_kh"] if params["Name_kh"]
      place.code = params["Code"] if params["Code"]
      place.parent_id = parent.id if params["Parent_code"]
      place.type = params["Type"].try(:downcase) if params["Type"]
      place.lat = params["Lat"] if params["Lat"]
      place.lng = params["Lng"] if params["lng"]
      place.abbr = params["Abbr"] if params["Abbr"]
      place.from_mis_app = true
      if place.save
        render json: {status: 'ok'}
      else
        render json: {status: 'error', error: place.errors.full_messages}
      end
    end
  end
end
