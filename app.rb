%w(rubygems cgi time hmac-sha2 base64 net/http).each { |lib| require lib }

ACCESS_IDENTIFIER = "access identifier"
SECRET_IDENTIFIER = "secret identifier"

def aws_escape(s)
  s.gsub(/[^A-Za-z0-9_.~-]/) { |c| '%' + c.ord.to_s(16).upcase }
end

amazon_endpoint= "webservices.amazon.com"
amazon_path = "/onca/xml"

proxy_addr = 'your proxy if you need it'
proxy_port = 8080

isbnNumber = "a book's ISBN number"

params = {
	:Service => "AWSECommerceService",
	:AssociateTag => "678832359350",
	:Operation => "ItemLookup",
	:IdType => "ISBN",
	:SearchIndex => "Books",
	:ItemId => isbnNumber,
	:ResponseGroup => "Images",
}

signing_params = {
  :AWSAccessKeyId => ACCESS_IDENTIFIER,
  :Timestamp => Time.now.gmtime.iso8601
}

params.merge!(signing_params)

canonical_querystring = params.sort.collect do |key, value|
  [aws_escape(key.to_s), aws_escape(value.to_s)].join('=')
end.join('&')

string_to_sign = "GET\n#{amazon_endpoint}\n#{amazon_path}\n#{canonical_querystring}"

hmac = HMAC::SHA256.new(SECRET_IDENTIFIER)
hmac.update(string_to_sign)
signature = Base64.encode64(hmac.digest).chomp

params[:Signature] = signature
querystring = params.sort.collect do |key, value|
  [aws_escape(key.to_s), aws_escape(value.to_s)].join('=')
end.join('&')

signed_url = URI("http://#{amazon_endpoint}#{amazon_path}?#{querystring}")
puts signed_url
res = Net::HTTP.get(signed_url)
Net:HTTP.bew("http://webservices.amazon.com", nil, proxy_addr, proxy_port).start { |http|
	res = http.get(signed_url)
}
puts res.body