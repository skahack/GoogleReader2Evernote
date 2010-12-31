
require 'net/https'
require 'uri'

Net::HTTP.version_1_2

module GoogleReaderToEvernote

  class GoogleReader

    HTTP = 'http://'
    HTTPS = 'https://'
    HOST = 'www.google.com'
    SERVICE = '/reader'
    SSL = ':443'
    UNSAFE = /[^-_.!~*()a-zA-Z\d]/

    def initialize(user, pass)
      @user = user
      @pass = pass
    end

    def timestamp
      (Time.now.to_f * 1000).to_i
    end

    #
    # low level layer
    #

    def get(url, params = {})
      request :get, url, params
    end

    def post(url, params = {})
      request :post, url, params
    end

    def request(method, url, params)

      data = params[:data]
      header = auth_header
      header.merge(params[:header]) if params[:header] 

      uri = URI.parse(url)

      case method
      when :get then
        request = Net::HTTP::Get.new uri.request_uri
      when :post then
        request = Net::HTTP::Post.new uri.request_uri
      end

      request.set_form_data data if data
      header.each {|k,v| request[k] = v}

      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true if uri.port == 443
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      response = http.request(request)
      response.read_body
    end

    def auth_header
      return {} unless @auth
      {"Authorization" => "GoogleLogin auth=#{@auth}"}
    end

    #
    # high level layer
    #

    def login
      data = {
        :Email => @user,
        :Passwd => @pass,
        :accountType => 'GOOGLE',
        :service => 'reader',
      }

      params = {
        :data => data,
      }

      response = post "#{HTTPS}#{HOST}#{SSL}/accounts/ClientLogin", params
      @auth = response.slice(/^Auth=(.*)$/, 1)
    end

    def feed_list(tag, continuation = nil)
      url = "#{HTTP}#{HOST}#{SERVICE}/api/0/stream/contents/#{tag}"
      query = [
        'n=20',
        "ck=#{timestamp.to_s}",
      ]
      query.push("c=#{continuation}") if continuation

      params = {}
      response = get "#{url}?#{query.join('&')}"
    end

    def user_info
      url = "#{HTTP}#{HOST}#{SERVICE}/api/0/user-info"
      params = {}
      response = get url
    end
  end
end
