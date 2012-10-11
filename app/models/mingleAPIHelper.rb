module MingleAPIHelper
  extend self

  MingleServer = '163.184.134.16'
  MingleServerPort = '8080'
  MingleUserName = 'admin'
  MinglePassword = '123456'

  def askMingle(apiURI, xpath)
    Enumerator.new do |y|
      open("http://#{MingleServer}:#{MingleServerPort}#{apiURI}", :http_basic_authentication => [MingleUserName, MinglePassword]) do |f|
        REXML::Document.new(f).each_element(xpath) do |e|
          y << e.text
        end
      end
    end
  end

  def get_response apiURI
    request = Net::HTTP::Get.new(apiURI)
    request.basic_auth(MingleUserName, MinglePassword)
    Net::HTTP.new(MingleServer, MingleServerPort).start { |http| http.request(request)}
  end
  
  def update apiURI, data
    putRequest = Net::HTTP::Put.new(apiURI)
    putRequest.basic_auth(MingleUserName, MinglePassword)
    putRequest.body = data
    Net::HTTP.new(MingleServer, MingleServerPort).start { |http| http.request(putRequest) }
  end
  
  def create apiURI, data
    putRequest = Net::HTTP::Post.new(apiURI)
    putRequest.basic_auth(MingleUserName, MinglePassword)
    putRequest.form_data = data
    Net::HTTP.new(MingleServer, MingleServerPort).start { |http| http.request(putRequest) }
  end
end