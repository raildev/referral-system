# coding: utf-8
class PlacesController < ApplicationController

  #GET /places
  def index
    @places = Place
    if(params[:query].present?)
      @places = @places.where "code LIKE :q OR name LIKE :q OR name_kh LIKE :q ", :q => "#{params[:query].strip}%"
      @places = @places.paginate :page => params[:page], :per_page => PerPage, :order => "id asc"
    else
      @places =  @places.paginate :page => params[:page], :per_page => PerPage, :order => "id asc"
    end
    render :file => "/places/_places.html.erb", :layout => false if request.xhr?
  end

  #
  def edit
    @place = Place.find(params[:id])
  end

  #
  def update
    @place = Place.find(params[:id])
    if @place.update_attributes(params[:place])
      flash["notice"] = "#{@place.description} has been updated successfully"
      redirect_to places_path(:page => params[:page])
    else
      render 'edit'
    end
  end

  #POST /places/confirm_import
  def confirm_import
    PlaceImporter.new(current_user.places_csv_file_name).import
  end

  #GET /places/import
  def import
    @title = "Upload"
  end

  #POST /places/upload_csv
  def upload_csv
    current_user.write_places_csv params[:admin][:csvfile]
    @places = PlaceImporter.new(current_user.places_csv_file_name).simulate

    return render 'no_places_to_import.html' if @places.blank?

    render 'upload_csv.html.erb'
  end

  #GET /places/csv_template
  def csv_template
    column_headers = PlaceImporter.column_headers.join(", ")
    send_data column_headers, :type => 'text/csv', :filename => 'places_template.csv'
  end

  #GET /map-view
  def map_view
    @country = Country.first

  end

  def sample_place
    places =  Place.all

    places.each do |place|
      place.lat = (rand(999999)/1000000.0) + 11 + rand(3)
      place.lng = (rand(999999)/1000000.0) + 102 + rand(5)
      place.save
      puts  "place: #{place.name}- lat: #{place.lat} - lng: #{place.lng} - type: #{place.type}"
    end
    render :text => "Done"
  end

  def sample_report
    type = ['F','V', 'M']
    sex = ['Male','Female']

    3000.times do |i|
      offset = rand(Place.count(:conditions=>"type in ( 'Village' OR 'HealthCenter' ) " ))
      place = Place.first(:offset => offset,:conditions=> "type in ( 'Village' OR 'HealthCenter' ) " )

      offset = rand(User.count)
      user = User.first(:offset => offset)

      attribute = {
        :malaria_type => type[rand(2)],
        :sex => sex[rand(1)],
        :age => 10 + rand(60),
        :place_id => place.id,
        :mobile => "09712"+ rand(9000).to_s,
        :village_id => (place.type == "HealthCenter")? place.villages.first.id: place.id,
        :sender_id => user.id,
        :created_at => rand(100).days.ago
      }
      Report.create!(attribute)
      puts "Created: report for #{user.user_name} with #{place.type}"

    end
    render :text=>"Done"
  end

  #GET places/map_report
  def map_report

    from = params[:from]
    to = params[:to]
    if(params[:id].blank?  || params[:id].to_i == 0)
        total = Report.count :conditions =>["created_at between :from and :to", {:from => from, :to => to}]
        country = Country.first
        places = [{
                    "name" => country.name,
                    "id" => country.id,
                    "type" => country.type,
                    "parent_id" => country.parent_id,
                    "lat" => country.lat,
                    "lng" => country.lng
                  }]
        creteria = Creteria.new

        places.each do |place|
          place["total"] = total
          creteria.add_record!(place["name"], place["total"])
        end
        creteria.prepare!
        clouds = creteria.cloud
        @result = {:place=>places, :cloud=>clouds }
      else
        place = Place.find(params[:id])
        if(place.type == "Country")
          sql = " SELECT province.*, count(report.id) as total FROM places province LEFT JOIN (SELECT * from reports WHERE created_at between '#{from}' AND '#{to}') AS report " +
              " ON province.id = report.province_id  where province.parent_id = #{place.id} GROUP BY province.id ORDER BY total DESC "
        elsif(place.type == "Province")
          sql = " SELECT od.*, count(report.id) as total FROM places od LEFT JOIN (SELECT * from reports WHERE created_at between '#{from}' AND '#{to}') AS  report " +
                " ON od.id = report.od_id WHERE  od.parent_id = #{place.id} GROUP BY od.id ORDER BY total DESC "
        elsif(place.type == "OD" )
          sql = " SELECT hc.*, count(report.id) as total FROM places hc LEFT JOIN (SELECT * from reports WHERE created_at between '#{from}' AND '#{to}') AS report " +
                " ON hc.id = report.health_center_id WHERE hc.parent_id = #{place.id} GROUP BY hc.id ORDER BY total DESC "
        elsif(place.type == "HealthCenter")
          sql = " SELECT village.*, count(report.id) as total FROM places village LEFT JOIN (SELECT * from reports WHERE created_at between '#{from}' AND '#{to}') AS  report " +
                " ON village.id = report.village_id WHERE village.parent_id = #{place.id} GROUP BY village.id ORDER BY total DESC "
        elsif(place.type == "Village")
          sql = " SELECT village.*, count(report.id) as total FROM places village LEFT JOIN (SELECT * from reports WHERE created_at between '#{from}' AND '#{to}') AS report " +
                " ON village.id = report.village_id WHERE village.id = #{place.id} GROUP BY village.id ORDER BY total DESC "
        end

        places = Place.connection.select_all(sql)
        creteria = Creteria.new
        places.each do |place|
          creteria.add_record!(place["name"], place["total"])
        end

        creteria.prepare!
        clouds = creteria.cloud
        @result =  {:place =>places, :cloud=> clouds, :parent => {:type=>place.type,:id=>place.id,:name=>place.name} }

    end
    render :json =>@result
  end

  def autocomplete
    places = Place.where("code LIKE :q OR name LIKE :q", :q => "#{params[:query]}%")
    places = places.where(:type => params[:type]) if params[:type].present?
    places = places.order(:code).all
    suggestions = places.map! { |x| "#{x.code} #{x.name} (#{x.class.to_s.underscore.humanize})" }
    render :json => {:query => params[:query], :suggestions => suggestions}
  end

end
