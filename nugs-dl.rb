#!/usr/bin/ruby
#
require 'net/http'
require 'json'
require 'date'
require 'pathname'
require 'optparse'

class NugsAPI

  def initialize
    @use_ssl = false
    @base_url = "http://streamapi.nugs.net/"
    @callback = "angular.callbacks._0"
    @base_url_api = @base_url + 'api.aspx'
    @base_url_secure_api = @base_url + 'secureapi.aspx'
    @base_url_player_api = @base_url + 'bigriver/subplayer.aspx?'
    @user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0'
    @referer = 'https://play.nugs.net/'
    @url_regex = /http[s]?:\/\/play\.nugs\.net\/#\/catalog\/recording\/([0-9]+\/?$)/
    @cookies = {}
    @url_template = "https://play.nugs.net/#/catalog/recording/"

    parse_args()
    puts @options.inspect
    #raise("JASON")
  end

  def auth
    #announce("Authenticating")

    params = {
      username: @options[:email],
      pw: @options[:password],
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
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: @use_ssl) do |http|
        http.request(req)
      end

    fixed_body = fix_body_with_callback(res.body)
    #res.each do |k, v|
      #puts "#{k}: #{v}"
    #end
    add_cookies(res.get_fields('set-cookie'))

    json = JSON.parse(fixed_body)
    #puts json.inspect
  end

  def get_subscriber_info
    #announce("Fetching subscriber info")

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
    req['Cookie'] = formatted_cookies()

    res =
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: @use_ssl) do |http|
        http.request(req)
      end

    fixed_body = fix_body_with_callback(res.body)
    add_cookies(res.get_fields('set-cookie'))
    json = JSON.parse(fixed_body)
    @subscriber_info = json
    json['Response']['subscriptionInfo']['planName']
  end

  def process_albums
    ensure_output_path()

    @options[:urls].each do |url|
      process_album(url)
    end
  end

  def process_album(url)
    album_id = extract_album_id_from_url(url)

    meta = get_album_meta(album_id)

    artist = meta['artistName']
    venue = meta['venue'].rstrip()
    performance_date = Date.strptime(meta['performanceDate'], '%m/%d/%Y')
    album_title = "#{performance_date.strftime('%Y-%m-%d')} - #{venue}"

    announce "Processing album #{artist} - #{album_title} (#{@options[:quality]})"

    folder = Pathname.new(File.join([@options[:output_path], artist, album_title, @options[:file_type]]))
    tracks = meta['tracks']

    puts ""
    tracks.each_with_index do |track, idx|
      #puts track.inspect
      track_id = track['trackID']
      title = track['songTitle']
      set_num = track['setNum']
      track_num = track['trackNum']
      file_path = folder + "#{set_num}-#{track_num} - #{title}#{@options[:ext]}"
      track_url = get_track_url(track_id, @options[:format_id])
      file_path.dirname.mkpath
      download(track_url, title, file_path, idx+1, tracks.length)
      puts ""
    end
  end

  # Private ##########

  def download(url, title, file_path, current, total)
    puts "Downloading track #{current} of #{total}: #{title}"

    uri = URI(url)

    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = @user_agent
    req['Referer'] = @referer
    req['Range'] = 'bytes=0-'
    req['Cookie'] = formatted_cookies()

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: @use_ssl) do |http|
      http.request req do |res|
        #res.each do |k, v|
          #puts "#{k}: #{v}"
        #end
        total_size = Integer(res.get_fields('content-length')[0]).to_f

        #file_path = '/Users/cjharrelson/Downloads/test.flac'

        last_percent = -1

        open file_path, 'w' do |io|
          res.read_body do |chunk|
            io.write chunk
            size = File.size(file_path).to_f
            percent = ((size/total_size) * 100).to_i
            puts "#{percent}%" if [0,25,50,75].include?(percent) && percent != last_percent
            last_percent = percent
          end
        end

        puts "Done"
      end
    end
  end

  def get_track_url(track_id, format_id)
    #announce("Fetching track URL for track ID: #{track_id}")
    params = {
		  HLS: '1',
		  platformID: format_id,
		  trackID: track_id,
      orgn: "nndesktop",
      callback: @callback,
    }
    #puts ""
    #puts params.inspect

    uri = URI(@base_url_player_api)
    uri.query = URI.encode_www_form(params)
    #puts uri.inspect

    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = @user_agent
    req['Referer'] = @referer
    req['Cookie'] = formatted_cookies

    res =
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: @use_ssl) do |http|
        http.request(req)
      end

    fixed_body = fix_body_with_callback(res.body)
    json = JSON.parse(fixed_body)
    #puts json.inspect
    stream_link = json['streamLink']

    if format_id == 4
      unless stream_link.include?('mqa24/')
        return get_track_url(track_id, 1)['streamLink']
      end
    end

    stream_link
  end

  def get_album_meta(album_id)
    #announce("Fetching album metadata")
    params = {
		  containerID: album_id,
      orgn: "nndesktop",
      callback: @callback,
      method: "catalog.container"
    }

    uri = URI(@base_url_api)
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = @user_agent
    req['Referer'] = @referer
    req['Cookie'] = formatted_cookies

    res =
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: @use_ssl) do |http|
        http.request(req)
      end

    fixed_body = fix_body_with_callback(res.body)
    add_cookies(res.get_fields('set-cookie'))
    json = JSON.parse(fixed_body)
    json['Response']
  end

  def add_cookies(cookies_from_headers)
    return nil if cookies_from_headers == nil

    cookies_hash = Hash.new

    cookies_from_headers.each do |cookie|
      k_v_str = cookie.split('; ')[0]
      k_v = k_v_str.split('=')
      cookies_hash[k_v[0]] = k_v[1]
    end

    @cookies = @cookies.merge(cookies_hash)
    #puts ""
    #puts "- NEW COOKIES -"
    #puts @cookies.inspect
  end

  def formatted_cookies
    #puts @cookies.inspect
    k_v_pairs =
      @cookies.map do |k,v|
        "#{k}=#{v}"
      end
    #puts k_v_pairs.inspect
    #puts @cookies.inspect
    k_v_pairs.join('; ')
  end

  def fix_body_with_callback(body)
    body.gsub(@callback + '(', '')
        .gsub(');', '')
  end

  def parse_args
    options = {}

    OptionParser.new do |opt|
      opt.on('-e', '--email EMAIL', 'The email for the user authentication') { |o| options[:email] = o }
      opt.on('-p', '--password PASSWORD', 'The password for the user authentication') { |o| options[:password] = o }
      opt.on('-u', '--url URL', 'The url to download from') { |o| options[:url] = o }
      opt.on('-q', '--quality QUALITY', 'The quality of the files to download') { |o| options[:quality] = o }
      opt.on('-l', '--list LIST', 'A file path containing a list of show URLs to download') { |o| options[:url_list_file_path] = o }
      opt.on('-o', '--output-path OUTPUT_PATH', 'A folder path to write the downloaded file to') { |o| options[:output_path] = o }
      opt.on('-s', '--show-ids SHOW_IDS', ' A comma delimited list of show IDs (ie. 29173)') { |o| options[:show_ids] = o }
    end.parse!

    if options[:output_path]
      options[:output_path] = Pathname.new(options[:output_path])
    else
      raise "You must provide the output path argument to proceed"
    end

    case options[:quality]
      when "1"
        options[:quality] = "16-bit / 44.1kHz FLAC"
        options[:format_id] = 1
      when "2"
        options[:quality] = "16-bit / 44.1kHz ALAC"
        options[:format_id] = 2
      when "4"
        options[:quality] = "24-bit MQA"
        options[:format_id] = 4
      else
        options[:quality] = "AAC 150"
        options[:format_id] = nil # TODO ????
    end

    unless options[:urls]
      options[:urls] = Array(options[:url])
    end

    if options[:show_ids]
      options[:show_ids] = Array(options[:show_ids].split(','))
      options[:urls] =
        options[:show_ids].map do |show_id|
          @url_template + show_id
        end
    end

    options[:urls].each_with_index do |url, idx|
      unless valid_url?(url)
        raise "The provided URL at list position #{idx+1} does not meet the expected spec: #{url}"
      end
    end

    case options[:format_id]
      when 1
        options[:ext] = '.flac'
        options[:file_type] = 'flac'
      when 2
        options[:ext] = '.alac.m4a'
        options[:file_type] = 'alac'
      else
        options[:ext] = '.m4a'
        options[:file_type] = 'm4a'
    end

    @options = options
  end

  def ensure_output_path
    @options[:output_path].mkpath
  end

  def valid_url?(url)
    url.match(@url_regex)
  end

  def extract_album_id_from_url(url)
    if m = url.match(@url_regex)
      m[1]
    else
      raise "Failed to extract album id from URL: #{url}"
    end
  end

  def announce(str)
    puts ""
    puts "===> #{str}"
  end

end

def print_title
  puts("""
 _____                 ____  __
|   | |_ _ ___ ___ ___|    \\|  |
| | | | | | . |_ -|___|  |  |  |__
|_|___|___|_  |___|   |____/|_____|
          |___|
  """)
end


print_title()
puts ""

nugs_api = NugsAPI.new
nugs_api.auth()
puts ""
plan_info = nugs_api.get_subscriber_info()
puts "Signed in successfully - " + plan_info + " account."
nugs_api.process_albums()
