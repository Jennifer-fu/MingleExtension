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

  def putToMingle(apiURI, data)
    if data.is_a? String
      putRequest = Net::HTTP::Put.new(apiURI)
      putRequest.basic_auth(MingleUserName, MinglePassword)
      putRequest.body = data
    else
      if data.is_a? Hash
        putRequest = Net::HTTP::Post.new(apiURI)
        putRequest.basic_auth(MingleUserName, MinglePassword)
        putRequest.form_data = data
      else
        raise 'data must be String or Hash type'
      end
    end

    Net::HTTP.new(MingleServer, MingleServerPort).start { |http| http.request(putRequest) }
  end
end