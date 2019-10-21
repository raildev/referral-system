class ProvincialHospital < Place
  alias_method :od, :parent
  delegate :province, :to => :od



end
