require 'net/http'

def get_html(domain, url)
  response = nil
  html = ''
  
  puts "HTTP Request: http://#{domain}#{url}"
  
  Net::HTTP.start(domain, 80) { |x|
  response = x.send('get', url, "")
    html = response.body
  }

  if ( (response.code.to_i == 200) && html[0,100].index('400').nil? && html.length > 20 )
    return html
  end
  
  return nil
	
rescue Exception => e
  puts "Exception: #{e.inspect}"
  
  return nil
end