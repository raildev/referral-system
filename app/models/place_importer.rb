# encoding: UTF-8

require 'csv'

class PlaceImporter

  def initialize file
    @file = file
  end

  def import_mis
    existing_places = Hash[Place.all.map{|x| [x.code, x]}]
    new_places = []
    levels = Place::Types[1..-1].map(&:constantize)
    i = 0
    r = 0
    white_list_place_type = ['Province', 'OD', 'HC', 'Village', 'FDH', 'PH', 'RH', 'HP']
    CSV.foreach @file, :headers => :first_row, :skip_blanks => true do |row|
      parent = nil

      r += 1
      code = (row[0] == 'Village') ? row[1].slice(0..7) : row[1]
      existing_place = existing_places[code]
      if existing_place.nil? && (white_list_place_type.include?(row[0]))
        place_type = row[0]
        if row[0] == 'Province'
          parent = Place.first
        else
          parent_code = row[7].split('-')[0]
          parent = Place.find_by_code(parent_code)
          if row[0] == 'HC'
            place_type = 'HealthCenter'
          elsif row[0] == 'FDH'
            place_type = 'FormerDistrictHospital'
          elsif row[0] == 'PH'
            place_type = 'ProvincialHospital'
          elsif row[0] == 'RH'
            place_type = 'ReferralHospital'
          elsif row[0] == 'HP'
            place_type = 'HealthPost'
          end
        end

        place = Place.new(name: row[2], name_kh: row[4], code: code,
          parent_id: parent.id, type: place_type, lat: row[5], lng: row[6],
          hierarchy: '', abbr: row[3], from_mis_app: true)

        if place.valid?
          place.type = place_type
          place.save
          i += 1
        end
      end
    end
    p "new place #{i}"
    p "all #{r}"

    new_places
  end

  def import
    process_csv
  end

  def simulate
    process_csv :simulate => true
  end

  private

  def process_csv(options = {})
    simulate = options[:simulate]

    existing_places = Hash[Place.all.map{|x| [x.code, x]}]
    new_places = []
    levels = Place::Types[1..-1].map(&:constantize)

    CSV.foreach @file, :headers => :first_row, :skip_blanks => true do |row|
      parent = nil
      levels.each do |level|
        fields = fill_fields row, level, :parent => parent
        existing_place = existing_places[fields[:code]]
        if existing_place
          parent = existing_place
        else
          parent = simulate ? level.new(fields) : level.create(fields)
          existing_places[parent.code] = parent
          new_places << parent
        end
      end
    end

    new_places
  end

  CSVIndexes = {
    Province => { :name => 0, :name_kh => 1, :code => 2 },
    OD => { :name => 3, :name_kh => 4, :code => 5 },
    HealthCenter => { :name => 6, :name_kh => 7, :code => 8 },
    Village => { :name => 9, :name_kh => 10, :code => 11, :lat => 12, :lng => 13 }
  }

  ColumnNames = {
    :name => 'name',
    :name_kh => 'name (khmer)',
    :code => 'code',
    :lat => 'latitude',
    :lng => 'longitude'
  }

  def fill_fields row, place_type, extensions
    fields = {}
    CSVIndexes[place_type].each do |name, column_index|
      fields[name] = row[column_index]
    end
    fields.merge!(extensions)
    fields
  end

  def self.column_headers
    headers = []
    column_count.times do |column_index|
      CSVIndexes.each do |place, fields|
        fields.each do |key, number|
          if column_index == number
            headers << "#{titleize place} #{ColumnNames[key]}"
          end
        end
      end
    end
    headers
  end

  def self.column_count
    count = 0
    CSVIndexes.each { |place, fields| count += fields.count }
    count
  end

  def self.titleize(place)
    place == OD ? "OD" : place.name.titleize
  end
end
