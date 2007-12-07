#require 'rubygems'
#require 'open-uri'
#require 'hpricot'
#
#@url = "http://www.bungie.net/stats/PlayerStatsHalo3.aspx?player="
#@response = ''
#
#def get_game_page_count(gamer_tag)
#  puts 'gt=' + gamer_tag
#	begin
#		# open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
#		open(@url + gamer_tag, "User-Agent" => "Ruby/#{RUBY_VERSION}") { |f|
#		
#		# Save the response body
#		@response = f.read
#		}
#
#		# HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
#		doc = Hpricot(@response)
#
#		str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div/div[4]/div/div/div/table/thead/tr/td").inner_html.to_s
#
#puts str
#
#		str = str[str.index('Displaying') + 'Displaying page 1 of '.length, 4]
#		if ( str.index(',') > 0 )
#			str = str[0, str.index(',')]
#		end
#		return str.to_i
#
#	rescue Exception => e
#	 puts 'EXCEPTION: ' + e.backtrace.to_s
#		return 0
#	end
#end

require 'rubygems'
require 'open-uri'
require 'hpricot'

BASE_URL = "http://www.bungie.net/stats/PlayerStatsHalo3.aspx?player="
@response = ''

def get_game_page_count(gamer_tag)
begin
  # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
  open(BASE_URL + gamer_tag.to_s.gsub(' ', '%20'), "User-Agent" => "Ruby/#{RUBY_VERSION}",
    "From" => "email@addr.com",
    "Referer" => "http://www.igvita.com/blog/") { |f|
                
    # Save the response body
    @response = f.read
  }
    
  # HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
  doc = Hpricot(@response)
    
  # Retrive number of comments
  str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div/div[4]/div/div/div").inner_html.to_s

	str = str[str.index('Displaying').to_i + 'Displaying page 1 of '.length, 4]
	if ( str.index(',').to_i > 0 )
		str = str[0, str.index(',')]
	end
	return str.to_i
    
rescue Exception => e
  exception(e)
  
  return 0
end
end
