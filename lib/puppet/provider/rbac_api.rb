class Puppet::Provider::Rbac_api < Puppet::Provider
  require 'net/https'
  require 'uri'
  require 'json'
  require 'openssl'
  require 'yaml'

  CONFIGFILE = "#{Puppet.settings[:confdir]}/classifier.yaml"

  confine :exists => CONFIGFILE

  # This is autoloaded by the master, so rescue the permission exception.
  @config = YAML.load_file(CONFIGFILE) rescue {}
  @config = @config.first if @config.class == Array

  def self.build_auth(uri)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.ssl_version = :TLSv1
    https.ca_file = Puppet.settings[:localcacert]
    https.key = OpenSSL::PKey::RSA.new(File.read(Puppet.settings[:hostprivkey]))
    https.cert = OpenSSL::X509::Certificate.new(File.read(Puppet.settings[:hostcert]))
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    https
  end

  def self.make_uri(path, prefix = '/rbac-api/v1')
    uri = URI.parse("https://#{@config['server']}:#{@config['port']}#{prefix}#{path}")
    uri
  end

  def self.fetch_redirect(uri_str, limit = 10)
    raise ArgumentError, 'HTTP redirection has reached the limit beyond 10' if limit == 0

    uri   = make_uri(uri_str, nil)
    https = build_auth(uri)
    Puppet.debug "RBAC API: REDIRECT #{uri.request_uri}"

    request = Net::HTTP::Get.new(uri.request_uri)
    res = https.request(request)

    case res
    when Net::HTTPSuccess then
      res
    when Net::HTTPRedirection then
      fetch_redirect(res['location'], limit - 1)
    else
      raise Puppet::Error, "An RBAC API error occured: HTTP #{res.code}, #{res.to_hash.inspect}"
    end
  end

  def self.get_response(endpoint)
    uri   = make_uri(endpoint)
    https = build_auth(uri)
    Puppet.debug "RBAC API: GET #{uri.request_uri}"


    request = Net::HTTP::Get.new(uri.request_uri)
    request['Content-Type'] = "application/json"
    res = https.request(request)

    if res.code != "200"
      raise Puppet::Error, "An RBAC API error occured: HTTP #{res.code}, #{res.body}"
    end
    res_body = JSON.parse(res.body)

    res_body
  end

  def self.delete_response(endpoint)
    uri   = make_uri(endpoint)
    https = build_auth(uri)
    Puppet.debug "RBAC API: DELETE #{uri.request_uri}"

    request = Net::HTTP::Delete.new(uri.request_uri)
    request['Content-Type'] = "application/json"
    res = https.request(request)

    if res.code != "200"
      raise Puppet::Error, "An RBAC API error occured: HTTP #{res.code}, #{res.body}"
    end
  end

  def self.put_response(endpoint, request_body)
    uri   = make_uri(endpoint)
    https = build_auth(uri)
    Puppet.debug "RBAC API: PUT #{uri.request_uri}"

    request = Net::HTTP::Put.new(uri.request_uri)
    request['Content-Type'] = "application/json"
    request.body = request_body.to_json
    res = https.request(request)

    if res.code != "200"
      raise Puppet::Error, "An RBAC API error occured: HTTP #{res.code}, #{res.body}"
    end
  end

  def self.post_response(endpoint, request_body)
    limit = 10
    uri   = make_uri(endpoint)
    https = build_auth(uri)
    Puppet.debug "RBAC API: POST #{uri.request_uri}"

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = "application/json"
    request.body = request_body.to_json
    res = https.request(request)
    case res
    when Net::HTTPSuccess then
      res
    when Net::HTTPRedirection then
      fetch_redirect(res['location'], limit - 1)
    else
      raise Puppet::Error, "An RBAC API error occured: HTTP #{res.code}, #{res.to_hash.inspect}"
    end
  end

end
