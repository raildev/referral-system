module Api::V1
  class ReportsController < ActionController::Base

    USER_NAME, PASSWORD = Mis.app_user, Mis.app_password
    before_filter :authenticate, :except => [ :index ]

    protect_from_forgery with: :exception

    # {place_code: 020110, message: "V18M002040506", sender: "85598481733"}
    def parse_message
      begin
        sender = User.find_by_phone_number(params[:sender])
        place = Place.find_by_code(params[:place_code])
        options = {text: params[:text], sender: sender, place_id: place.id,
          sender_address: params[:sender], from_mis_app: true}
        report = Report.process(options)
        report._send_alert_to_other

        if report
          render json: {status: 'ok'}
        else
          render json: {status: 'error'}
        end
      rescue Exception => e
        render json: {status: 'error', message: e.message}
      end
    end

    private
      def authenticate
        authenticate_or_request_with_http_basic do |user_name, password|
          user_name == USER_NAME && password == PASSWORD
        end
      end

  end
end
