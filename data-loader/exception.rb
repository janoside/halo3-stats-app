def exception(e)
  puts "\n************************************\nEXCEPTION: #{e.inspect}\n"
  e.backtrace.each do |trace_loc|
    puts "\t#{trace_loc}"
  end
end