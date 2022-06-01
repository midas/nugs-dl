require 'net/http'
require 'json'

class NugsAPI

  def initialize
    @base_url = "https://streamapi.nugs.net/"
    @callback = "angular.callbacks._0"
    @base_url_secure_api = @base_url + 'secureapi.aspx'
    @user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0',
    @referer = 'https://play.nugs.net/'
  end

  def auth(email, password)
    params = {
      username: email,
      pw: password,
      orgn: "nndesktop",
      callback: @callback,
      method: "user.site.login"
    }

    uri = URI(@base_url_secure_api)
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = @user_agent
    req['Referer'] = @referer

    res =
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

    fixed_body = fix_body_with_callback(res.body)
    #res.each do |k, v|
      #puts "#{k}: #{v}"
    #end
    all_cookies = res.get_fields('set-cookie')
    cookies_array = Array.new
    all_cookies.each do |cookie|
      cookies_array.push(cookie.split('; ')[0])
    end
    cookies = cookies_array.join('; ')
    @auth_cookie = cookies

    json = JSON.parse(fixed_body)
    #puts json.inspect
  end

  def get_subscriber_info
    params = {
      orgn: "nndesktop",
      callback: @callback,
      method: "user.site.getSubscriberInfo"
    }

    uri = URI(@base_url_secure_api)
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = @user_agent
    req['Referer'] = @referer
    req['Cookie'] = @auth_cookie

    res =
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

    fixed_body = fix_body_with_callback(res.body)
    json = JSON.parse(fixed_body)
    @subscriber_info = json
    json['Response']['subscriptionInfo']['planName']
  end

  def fix_body_with_callback(body)
    body.gsub(@callback + '(', '')
        .gsub(');', '')
  end

end


email = "taylortennispro@icloud.com"
password = "Auburn02"
quality = 2

nugs_api = NugsAPI.new
nugs_api.auth(email, password)
puts ""
plan_info =  nugs_api.get_subscriber_info()
puts "Signed in successfully - " + plan_info + " account."
