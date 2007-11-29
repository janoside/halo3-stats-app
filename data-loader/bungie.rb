require 'net/http'
require '/var/lib/gems/1.8/gems/xml-simple-1.0.11/lib/xmlsimple.rb'
require 'http.rb'

def get_summary_data(xml_doc)
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

def get_game_page_count(xml_doc)
  puts 'haha'	
  table = xml_doc['body'][0]['div'][0]['form']['aspnetForm']['div'][2]['div'][1]['div'][1]['div'][0]['div'][0]['div'][0]['div'][2]['div'][0]['div'][0]['div'][0]
  puts table.inspect
  
  return 0
end