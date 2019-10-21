class ReferralHospital < Place
  alias_method :od, :parent
  delegate :province, :to => :od

# self.inheritance_column = 'type'
end
