class GoogleMap
  Config = YAML.load_file(File.expand_path('../../../config/googlemap.yml', __FILE__))[Rails.env]

  def self.api_key
    Config['api_key']
  end
end
