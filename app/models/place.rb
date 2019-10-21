class Place < ActiveRecord::Base
  # The hierarchy of place types. Must be ordered by top to bottom.
  Types = ["Country", "Province", "OD", "HealthCenter", "Village", "FormerDistrictHospital", "ProvincialHospital", "ReferralHospital", "HealthPost"]

  has_many :users
  has_many :reports
  has_many :sub_places, :class_name => "Place", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Place"
  before_save :unset_hierarchy, :unless => lambda { changes.except(:hierarchy).empty? }
  after_save :set_hierarchy, :if => lambda { hierarchy.nil? }

  validates_presence_of :name
  validates_presence_of :code, :unless => :country?
  validates_uniqueness_of :code

  before_validation :set_parent_from_intended_parent_code, :if => lambda { @intended_parent_code }
  validate :intended_parent_code_must_exist, :if => lambda { @intended_parent_code && !parent }

  def self.list
    all.map{|place| place.intended_place_code }
  end

  def self.find_by_code(code)
    return nil if code.blank?
    pieces = code.strip.split(/\s/, 2)
    where(:code => (pieces.length == 2 ? pieces.first : code)).first
  end

  def self.foreign_key
    self.to_s.foreign_key
  end

  def foreign_key
    self.class.foreign_key
  end

  def self.sub_place_class
    Types[1 + Types.index(to_s)] || Types.last
  end

  def sub_place_class
    self.class.sub_place_class
  end

  def self.parent_class
    Types[Types.index(to_s) - 1] || Types.first
  end

  def self.get_parent_class type
     if type == "Village"
        cls = HealthCenter
     elsif type == "HealthCenter"
       cls = OD
     elsif type == "OD"
       cls = Province
     end
     cls
  end

  def intended_place_code
    "#{code} - #{name}"
  end

  def parent_class
    self.class.parent_class
  end

  def name_with_code
    "#{self.code} #{self.name}"
  end

  def intended_parent_code
    parent.try(:description)
  end

  def intended_parent_code=(code)
    @intended_parent_code = code
  end

  def description
    "#{code} #{name} (#{self.class.name.titleize})"
  end

  def short_description
    "#{code} #{name}"
  end

  def self.find_from_parent id
    if !id.nil?
      where(["parent_id = :parent_id", { :parent_id => id}])
    else
      []
    end
  end

  def self.auto_complete_type_ahead options
    places = self.search_for_autocomplete(options).limit(10)
    result = places.map{|place| place.intended_place_code}
    result
  end

  def self.search_for_autocomplete(options)
    result = where("1=1")
    if !options[:query].blank?
      if options[:query] =~ /^\s*\d+\s*$/
        result = result.where "code LIKE ?", "#{options[:query].strip}%"
      else
        result = result.where "name LIKE :q OR name_kh LIKE :q ", :q => "#{options[:query].strip}%"
      end
    end

    if !options[:type].blank?
        result = result.where "type = :type ", :type => "#{options[:type].strip}"
    end
    result
  end

  def get_parent type
    p = self
    while p != nil && p.class != type
      p = p.parent
    end
    p
  end

  def acknowledgemente body
    valid_users = users.select{|user| (user.status && user.is_from_referral?)}
    valid_users.map{|user| user.message(body) }
  end

  def acknowledge_facilitator(body)
    valid_users = users.select{|user| (user.status && user.is_from_referral? && user.role == User::ROLE_REF_FACILITATOR)}
    valid_users.map{|user| user.message(body) }
  end

  def create_alerts body, options = {}
    users.reject{|user| (user == options[:except] or !user.status or !user.is_from_md0?) }.map{|user| user.message(body) }
  end

  def reports
    Report.at_place self
  end

  def name
    attributes['name'] || ''
  end

  Types.each do |constant|
    # Define generic methods to get the village, country, etc., of a place.
    # This base class just returns self if the type is the name of the method, otherwise nil.
    class_eval %Q(
      def #{constant.tableize.singularize}
        type == "#{constant}" ? self : nil
      end
    )

    # Define question methods to ask if a place is of a given place type, i.e.: place.village?
    class_eval %Q(
      def #{constant.tableize.singularize}?
        type == "#{constant}"
      end
    )
  end

  private

  def set_hierarchy
    self.hierarchy = (self.parent_id ? "#{self.parent.hierarchy}." : '') + self.id.to_s
    update :hierarchy => self.hierarchy
  end

  def unset_hierarchy
    self.hierarchy = nil
  end

  def set_parent_from_intended_parent_code
    self.parent = Place.find_by_code @intended_parent_code
  end

  def intended_parent_code_must_exist
    errors.add :intended_parent_code, "doesn't exist"
  end

end
