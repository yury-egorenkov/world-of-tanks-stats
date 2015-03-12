class HomeController < ApplicationController

  COUNTRIES = 
  TANK_TYPES = %w(  Тяж1 ПТ-САУ )
  TYPES = %w( Arm maxFire Durability Guns )

  def index
    all_tanks_spec = [
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


    table ||= []

    ap all_tanks_spec

    all_tanks_spec.each do |tank_spec|
      tank_spec[:countries].each do |country|
        table << by_country_and_tank_type(country, tank_spec)
      end      
    end

    render json: table.flatten
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

  def get_data(country, tankType, type)
    url = URI.encode("http://tanks-vs.com/getData_whole.php?country=#{country}&tankType=#{tankType}&type=#{type}&startLevel=1&quantity=10")

    ap url

    response = RestClient.get url, 
      {cookies: 
        {'PHPSESSID' => '569cfe64aface11e37d39b59e79d222f', 
         'uid_zxcv' => 'bc5dd45855013f33b0bf695503ff3402',
         'loggedIn' => '1'
        }
      }

    response_body = response.body
    error_index = response_body.index("{")
    response_body = response_body[error_index, response_body.length] if error_index && error_index > 0

    OpenStruct.new JSON.parse(response_body)
  end
end
