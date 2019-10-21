module Api::V1
  class UsersController < ActionController::Base
    def create
      place_code = params["Place"].split('-')[0]
      place = Place.find_by_code(place_code)
      province_id = Place.find_by_code(place_code.slice(0..1)).try(:id)
      od_id = Place.find_by_code(place_code.slice(0..3)).try(:id)
      health_center_id = Place.find_by_code(place_code.slice(0..5)).try(:id)
      village_id = Place.find_by_code(place_code.slice(0..7)).try(:id)

      user = User.find_by_user_name(params["Username"]) || User.new
      user.user_name = params["Username"]
      user.password = params["Password"] if params["Password"]
      user.password_confirmation = params["Password"] if params["Password"]
      user.phone_number = params["Phone"] if params["Phone"]
      user.email = params["Email"] if params["Email"]
      user.role = params["Role"].downcase if params["Role"]
      if params["Place"]
        user.place_class = place.class.to_s
        user.health_center_id = health_center_id
        user.od_id = od_id
        user.province_id = province_id
        user.country_id = 1
        user.village_id = village_id
        user.place_id = place.id
      end
      user.apps_mask = 1
      user.status = (params["status"] == 1) if params["Status"]
      user.from_mis_app = true

      if user.save
        render json: {status: 'ok'}
      else
        render json: {status: 'error', error: user.errors.full_messages}
      end
    end
  end
end
