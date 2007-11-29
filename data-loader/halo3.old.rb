require 'net/http'
require 'xmlsimple'

#GAMER_TAGS = ['JAN0SIDE']
GAMER_TAGS = ['JAN0SIDE', 'meesturbo', 'rcp1000', 'badassmof01234', 'strikebox']

max_length = 0
GAMER_TAGS.each do |gamer_tag|
	if ( gamer_tag.length > max_length )
		max_length = gamer_tag.length
	end
end
FIELDS = [:kd_ratio, :kills_per_game, :deaths_per_game]
FIELD_NAMES = {:kd_ratio => 'Kill/Death', :kills_per_game => 'Kill/Game', :deaths_per_game => 'Death/Game'}
FIELD_ORDERS = {:kd_ratio => :high, :kills_per_game => :high, :deaths_per_game => :low}

DOMAIN = "www.bungie.net"

URL_LIST = {
	:ranked => "/stats/Halo3/CareerStats.aspx?player=",
	:social => "/stats/halo3/CareerStats.aspx?social=true&map=0&player="
}

def get_xml(domain, url)
	response = nil
	html = ''
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

def interpret_xml(xml_doc)
	data = {}
	
	table = xml_doc['body'][0]['div'][0]['form']['aspnetForm']['div'][2]['div'][1]['div'][1]['div'][0]['div'][0]['div'][2]['div'][1]['div'][1]['div'][0]['div'][0]['div'][0]['div'][0]['div'][0]['div'][0]['div'][0]['table'][0]
	data[:kills] = table['tr'][0]['td'][1]['content'].to_i
	data[:deaths] = table['tr'][1]['td'][1]['content'].to_i
	data[:kd_ratio] = data[:kills] * 1.0 / data[:deaths]
	
	game_count = xml_doc['body'][0]['div'][0]['form']['aspnetForm']['div'][2]['div'][1]['div'][1]['div'][0]['div'][0]['div'][2]['div'][1]['div'][0]['div'][0]['div'][0]['ul'][0]['li'][0].to_s
	game_count = game_count[15, game_count.index(' ') - 1].to_i
	
	data[:games] = game_count
	data[:kills_per_game] = data[:kills] * 1.0 / data[:games]
	data[:deaths_per_game] = data[:deaths] * 1.0 / data[:games]
	
	return data
end

def interpret_file_xml(xml_doc)
end

def get_game_data(gamer_tag)
	game_data = {}
	
	URL_LIST.each do |name, url|
		xml = get_xml(DOMAIN, url + gamer_tag)
		if ( !xml.nil? )
			xml_doc = XmlSimple.xml_in(xml, {'KeyAttr' => 'name'})
			
			game_data[name] = interpret_xml(xml_doc)
		end
	end
	
	puts "Data Retrieved for #{gamer_tag}"
	
	return game_data
end

all_game_data = {}
GAMER_TAGS.each do |gamer_tag|
	all_game_data[gamer_tag] = get_game_data(gamer_tag)
	
	global_data = {:kills => 0, :deaths => 0, :games => 0}
	all_game_data[gamer_tag].each do |data_type, data|
		global_data[:kills] = global_data[:kills] + data[:kills]
		global_data[:deaths] = global_data[:deaths] + data[:deaths]
		global_data[:games] = global_data[:games] + data[:games]
	end
	
	global_data[:kd_ratio] = global_data[:kills] * 1.0 / global_data[:deaths]
	global_data[:kills_per_game] = global_data[:kills] * 1.0 / global_data[:games]
	global_data[:deaths_per_game] = global_data[:deaths] * 1.0 / global_data[:games]
	
	all_game_data[gamer_tag][:global] = global_data
end

puts "----------------------------------"

GAMER_TAGS.each do |gamer_tag|
	data_set = all_game_data[gamer_tag][:global]
	
	puts "#{gamer_tag}:"
	puts "Kills:		#{data_set[:kills].to_s}"
	puts "Deaths:		#{data_set[:deaths]}"
	puts "Games:		#{data_set[:games]}"
	puts "KD Ratio:	#{data_set[:kd_ratio]}"
	puts "K/G:		#{data_set[:kills_per_game]}"
	puts "D/G:		#{data_set[:deaths_per_game]}"
	puts ''
end

sort_lists = {}
FIELDS.each do |field|
	sort_lists[field] = []
	GAMER_TAGS.each do |gamer_tag|
		sort_lists[field] << {:gamer_tag => gamer_tag, :value => all_game_data[gamer_tag][:global][field]}
	end
	
	if ( FIELD_ORDERS[field] == :low )
		sort_lists[field].sort! {|a, b| a[:value] <=> b[:value]}
	else
		sort_lists[field].sort! {|a, b| b[:value] <=> b[:value]}
	end
	
	index = 1
	puts FIELD_NAMES[field]
	sort_lists[field].each do |ordered_item|
		puts "#{index}. #{ordered_item[:gamer_tag]}		(#{ordered_item[:value]})"
		index = index + 1
	end
	puts ''
end
