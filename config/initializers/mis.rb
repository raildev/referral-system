class Mis
  Config = YAML.load_file(File.expand_path('../../../config/mis.yml', __FILE__))[Rails.env]

  def self.app_user
    Config['app_user']
  end

  def self.app_password
    Config['app_password']
  end
end
