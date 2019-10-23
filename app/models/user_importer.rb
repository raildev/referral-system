require 'csv'
class UserImporter < CSV

  def self.simulate file
    users = []
    process_csv file do |user|
      user.valid?
      users << user
    end
    users
  end

  def self.import_mis file
    existing_users = Hash[User.all.map{|x| [x.phone_number, x]}]
    i = 0
    CSV.foreach file, :headers => :first_row, :skip_blanks => true do |row|
      place_code =  row[0].length == 10 ? row[0].slice(0..7) : row[0]
      phone_number = row[1] ? row[1].gsub(/^0/, '855') : ''
      role = row[2].downcase

      place = Place.find_by_code(place_code)
      province_id = Place.find_by_code(place_code.slice(0..1)).try(:id)
      od_id = Place.find_by_code(place_code.slice(0..3)).try(:id)
      health_center_id = Place.find_by_code(place_code.slice(0..5)).try(:id)
      village_id = Place.find_by_code(place_code.slice(0..7)).try(:id)
      existing_user = existing_users[phone_number]
      if(existing_user.nil?)
        user = User.new(user_name: phone_number, password: '123456', password_confirmation: '123456', phone_number: phone_number, role: role,
         place_class: place.class.to_s, health_center_id: health_center_id, od_id: od_id, province_id: province_id, country_id: 1,
         village_id: village_id, status: true, apps_mask: 1, place_id: place.id, from_mis_app: true)
        if user.valid?
          user.save
          i += 1
        else
          p "#{phone_number} : #{user.errors.full_messages}"
        end
      end
    end
    p "new user #{i}"
  end

  def self.import file
    count = 0
    process_csv file do |user|
      count += 1 if user.save
    end
    count
  end

  def self.process_csv(file)
    self.foreach(file, :headers => :first_row, :skip_blanks => true) do |row|
      attributes = {
         :user_name => row[0],
         :email => row[1],
         :phone_number => row[2],
         :password => row[3],
         :password_confirmation => row[3],
         :intended_place_code => row[4],
         :role => self.role(row[5])
      }
      user =  User.new attributes
      yield user
    end
  end

  def self.role str
    str.blank? ? "default" : str
  end

end
