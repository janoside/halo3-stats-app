class Log

  def Log.info(str)
    MainLogger.info(str)
  end

  def Log.exception(e)
    MainLogger.info("****************************************\nEXCEPTION [#{Time.now().to_s}]: #{e.to_s}\n\nSTACKTRACE:\n")
    
    e.backtrace.each do |trace_location|
      MainLogger.info("\t#{trace_location.to_s}")
    end
    
    MainLogger.info("****************************************\n")
  end
end