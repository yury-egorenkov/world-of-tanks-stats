class HomeController < ApplicationController
  
  TYPES = %w( Arm maxFire Durability Guns )

  ALL_TANKS_SPEC = [
      {
        tank_type: 'Средние',
        tank_type_name: 'Средние',
        countries: %w( Ge Ru Am UK )
      },
      {
        tank_type: 'Тяж1',
        tank_type_name: 'Тяжелые',
        countries: %w( Ge Ru )
      },
      {
        tank_type: 'Тяж2',
        tank_type_name: 'Тяжелые',
        countries: %w( Ge Ru )
      },      
      {
        tank_type: 'Тяж',
        tank_type_name: 'Тяжелые',
        countries: %w( Am UK )
      },      
      {
        tank_type: 'ПТ-САУ',
        tank_type_name: 'ПТ-САУ',
        countries: %w( Ge Ru Am )
      },      
      {
        tank_type: 'ПТ-САУ2',
        tank_type_name: 'ПТ-САУ',
        countries: %w( Am )
      }
    ]

  def index
  end

  def tanks_data      
    render json: load_all_tanks
  end

  def images
    @tanks = load_all_tanks
  end

  def mask
  end

  # Танк раскраска
  # http://localhost:3000/home/tank_image/T-34-85?%D0%9B%D0%BE%D0%B1=ff0000&%D0%91%D0%BE%D1%80%D1%82=00ff00&%D0%9A%D0%BE%D1%80%D0%BC%D0%B0=0000ff&%D0%9B%D0%BE%D0%B1-%D0%B1%D0%B0%D1%88%D0%BD%D0%B8=070707&%D0%91%D0%BE%D1%80%D1%82-%D0%B1%D0%B0%D1%88%D0%BD%D0%B8=bbaaff&%D0%9A%D0%BE%D1%80%D0%BC%D0%B0-%D0%B1%D0%B0%D1%88%D0%BD%D0%B8=dc604f
  def tank_image
    opacity = 0.99

    name = params[:name]

    path = Rails.root.join('app', 'assets', 'images', 'tanks')
    image = Magick::Image.read("#{path}/#{name}.png").first {self.background_color = "none"}

    unless File.exists?("#{path}/#{name}.svg")
      send_data image.to_blob, :disposition => 'inline', 
        type: image.mime_type
      return
    end

    svg = File.read("#{path}/T-34-85.svg")
    doc = Nokogiri::XML.parse(svg)
    %w( Лоб Борт Корма Лоб-башни Борт-башни Корма-башни ).each do |item|
      doc.css("##{item}").set(:fill, "##{params[item]}") if params[item]  
    end
    
    File.open("#{path}/T-34-85.svg", "w") do |file|
      file.puts doc
    end

    `convert -background none "#{path}/#{name}.svg" "#{path}/#{name}-mask.png"`

    mask = Magick::Image.read("#{path}/#{name}-mask.png").first

    composite = image.dissolve(mask, 0.5, 1, Magick::CenterGravity)

    resized = composite #.resize_to_fit(400, 400)
    send_data resized.to_blob, :disposition => 'inline', type: resized.mime_type
  end

  def load_all_tanks
    all_tanks ||= []

    ALL_TANKS_SPEC.each do |tank_spec|
      tank_spec[:countries].each do |country|
        all_tanks << by_country_and_tank_type(country, tank_spec)
      end      
    end
  
    all_tanks.flatten    
  end

  def by_country_and_tank_type(country, tank_spec)
    tank_type = tank_spec[:tank_type]

    arm = get_data(country, tank_type, TYPES[0] )
    max_fire = get_data(country, tank_type, TYPES[1] )
    durability = get_data(country, tank_type, TYPES[2] )    

    arm.categories.enum_for(:each_with_index).map do |tank, i|
      result ||= {}
      result['name'] = tank
      result['level'] = arm['level'][i]
      result['country'] = country
      result['tank_type'] = tank_spec[:tank_type_name]

      image = get_data(country, tank_type, TYPES[0], result['level'], 1).pic
      result['image'] = "http://tanks-vs.com/#{image}"

      arm.series.each do |serie|
        result[serie['name']] = serie['data'][i]
      end

      max_fire.series.each do |serie|
        result[serie['name']] = serie['data'][i]
      end

      durability.series.each do |serie|
        result[serie['name']] = serie['data'][i]
      end

      result      
    end    
  end

  def get_data(country, tankType, type, start_level = 1, quantity = 10)
    url = URI.encode("http://tanks-vs.com/getData_whole.php?country=#{country}&tankType=#{tankType}&type=#{type}&startLevel=#{start_level}&quantity=#{quantity}")

    ap url

    response = RestClient.get url, 
      {cookies: 
        {'PHPSESSID' => '569cfe64aface11e37d39b59e79d222f', 
         'uid_zxcv' => 'bc5dd45855013f33b0bf695503ff3402',
         'loggedIn' => '1'
        }
      }

    OpenStruct.new JSON.parse(exclude_error(response.body))
  end

  def exclude_error(body)
    response_body = body
    error_index = body.index("{")
    response_body[error_index, body.length] if error_index && error_index > 0
    response_body
  end
end
