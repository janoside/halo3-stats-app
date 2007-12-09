class Utility

  def Utility.to_float(val, digits)
    return val.to_s[0..digits].to_f
  end
  
  def Utility.list(vals, separator)
    str = ''
    
    index = 0
    vals.each do |val|
      str = str + val.to_s
      if ( index < (vals.length - 1) )
        str = str + separator.to_s
      end
      
      index = index + 1
    end
    
    return str
  end
end