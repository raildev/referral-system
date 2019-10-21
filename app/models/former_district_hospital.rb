class FormerDistrictHospital < Place
  alias_method :province, :parent
  # alias_method :od, :parent
  # delegate :province, :to => :od


end
