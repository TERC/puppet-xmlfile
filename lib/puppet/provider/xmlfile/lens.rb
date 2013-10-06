require 'rexml/document'

# XMLLens wraps around rexml/document and XPath to provide
# augeas esque-manipulation of an xml file.
class XmlLens
  # Initialized with the file(preloaded), any changes and any conditions
  def initialize(xml, changes = nil, conditions = nil)
    raise ArgumentError unless xml.is_a? REXML::Document
    @xml = xml
    @operations = Array.new
    @validations = Array.new
    
    # Initialize our ops and validations
    # these get batched and executed en-masse
    unless changes.nil?
      if changes.is_a? Array
        changes.each { |change| parser(change) }
      elsif changes.is_a? String
        parser(changes)
      else
        raise ArgumentError
      end
    end
    
    unless conditions.nil?
      if conditions.is_a? Array
        conditions.each { |condition| parser(condition) }
      elsif conditions.is_a? String
        parser(conditions)
      end
    end
  end
    
   # Wrap around XPath.match
  def match(match, xml = @xml)
    REXML::XPath.match(xml, match)
  end 
  
  # Evaluates.  Calls the procs that have been loaded.
  def evaluate
    # First up validations
    @validations.each do |validate|
      next if validate.call
      return @xml
    end
    # Those passed, so next up is actual operations
    @operations.each do |operation|
      operation.call
    end
    return @xml
  end
  
  # Clears an element
  def clear(path)
    puts "clear #{path.inspect}"
    if path.is_a? Array
      path.each do |p|
        p.elements.each do |child|
          p.elements.delete(child)
        end
        p.text = nil
        p.attributes.keys.each do |key|
          p.attributes.delete(key)
        end
      end
    elsif path.is_a? REXML::Element
      path.elements.each do |child|
        path.elements.delete(child)
      end
      path.text = nil
      path.attributes.keys.each do |key|
        path.attributes.delete(key)
      end
    else
      raise ArgumentError
    end
  end
   
  # Checks if a match has a certain value(attribute or text)
  def get(match, expr, value, attr)
    retval = false
    match.each do |m|
      if attr and attr.length > 0
        retval = evaluate_expression(m.attributes[attr], expr, value)
      else
        retval = evaluate_expression(m.text, expr, value)
      end
      break if retval
    end
    return retval
  end
  
  # Deletes a node
  def rm(path)
    if path.is_a? Array
      path.each do |p|
        p.parent.elements.delete(p) if p.parent
      end
    elsif path.is_a? REXML::Element
      path.parent.elements.delete(p) if path.parent
    else
      raise ArgumentError
    end
  end
  
  # Sets a node or node attribute to a value.  Creates it if it doesn't exist
  def set(element, value, attribute, path)
    unless element.nil?
      set_element = element.first
    else
      built_path = build_path(path.scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      if built_path[:exists]
        set_element = built_path[:final_path].first
      else
        set_element = built_path[:final_path].first
        built_path[:remainder].each do |add|
          set_element = set_element.elements.add(add)
        end
      end
    end
    if attribute
      set_element.attributes[attribute] = value
    else
      set_element.text = value
    end
  end
  
  # Type is ignored for now as I didn't really have a use case for it.
  def sort(element, attr, type)
    if element.is_a?(Array)
      element.each do |elem|
        case attr
        when "text"
          sorted = elem.elements.sort { |e1, e2| e1.text <=> e2.text }
        when nil
          sorted = elem.elements.sort { |e1, e2| e1.name <=> e2.name }
        else
          sorted = elem.elements.sort { |e1, e2| e1.attributes[attr] <=> e2.attributes[attr] }
        end
        elem.elements.each { |a| elem.elements.delete(a) }
        sorted.each { |a| elem.add_element(a) }
      end
    elsif element.is_a? REXML::Element
      case attr
      when "text"
        sorted = elem.elements.sort { |e1, e2| e1.text <=> e2.text }
      when nil
        sorted = elem.elements.sort { |e1, e2| e1.name <=> e2.name }
      else
        sorted = elem.elements.sort { |e1, e2| e1.attributes[attr] <=> e2.attributes[attr] }
      end
      element.elements.each { |a| element.elements.delete(a) }
      sorted.each { |a| element.add_element(a) }
    end
  end
   
  private  
  def parser(string)
    parse = string.match(/^(\S+)\ (.*)$/)
    return if parse.nil?
    
    cmd = parse[1]
    args = parse[2]
    case cmd
    when "clear"
      # Break down the paths
      built_path = build_path(parse[2].scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      
      if built_path[:exists] # Only clear if the thing exists
        @operations.push( Proc.new { self.clear(built_path[:final_path]) } )
      end
    when "get"
      query = parse[2].match(/^(.*)\ (==|!=|<|>|<=|>=)\ \"(.*)\"$/)
      raise ArgumentError if query.nil?
      attribute = query[1].match(/^(.*)([^\[]#attribute\/)(.*)$/)
      
      unless attribute.nil?
        path = attribute[1]
        attr = attribute[3]
      else
        path = query[1]
        attr = nil
      end
      
      built_path = build_path(path.scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      if built_path[:exists]
        @validations.push( Proc.new { self.get(built_path[:final_path], query[2], query[3], attr) })
      else
        @validations.push( Proc.new { evaluate_expression( nil, query[2], query[3] ) } )
      end
    when "ins"  
      args = parse[2].match(/(.*)\ (before|after)\ (.*)$/)
      raise ArgumentError if args.nil?
      built_path = build_path(args[3].scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      if built_path[:exists]
        args[1].scan(/\/(^\/)/).each do |item|
          puts item        
        end
        case args[2]
        when "before"
        when "after"
        end
      end
    when "match"
      query = parse[2].match(/(.*)\ size\ (==|!=|<|>|<=|>=)\ (\d)+$/)
      raise ArgumentError if query.nil?
      
      built_path = build_path(query[1].scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      if built_path[:exists]
        @validations.push( Proc.new { evaluate_expression(built_path[:final_path].size, query[2], query[3].to_i) })
      else
        @validations.push( Proc.new { evaluate_expression(0, query[2], query[3]) })
      end
    when "rm"
      built_path = build_path(parse[2].scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      
      if built_path[:exists] # Only clear if the thing exists
        @operations.push( Proc.new { self.rm(built_path[:final_path]) } )
      end
    when "set"
      args = parse[2].match(/(.*)\ \"(.*)\"$/)
      raise ArgumentError if args.nil?
      attribute = args[1].match(/^(.*)([^\[]#attribute\/)(.*)$/)
      
      unless attribute.nil?
        path = attribute[1]
        attr = attribute[3]
      else
        path = args[1]
        attr = nil
      end
      
      built_path = build_path(path.scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      if built_path[:exists]
        @operations.push( Proc.new { set(built_path[:final_path], args[2], attr, nil) } )
      else
        path = collapse_functions(path)
        @operations.push( Proc.new { set(nil, args[2], attr, path) } )
      end
    when "sort"
      # sort /foo/bar [attribute|text] [desc|asc]
      args = parse[2].match(/(.*)(\ )?(.*|text)?(\ )?(desc|asc)?$/)
      raise ArgumentError if args.nil?
      attribute = args[3]
      unless attribute.nil?
        attr = args[3]
      else
        attr = nil
      end
      
      built_path = build_path(args[1].scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/))
      if built_path[:exists]
        @operations.push( Proc.new { sort(built_path[:final_path], attr, args[5]) } )
      end
    else
      raise ArgumentError
    end
  end
  
  def build_path(args)
    # We should be getting the output of scan here so it should be an array of arrays
    raise ArgumentError unless args.is_a? Array
    remainder = args.map { |m| m.first }
    final_path = self.match(String.new)
    exists = true
    
    args.each do |path|
      match = evaluate_match(self.match(path.first, final_path), path.last)
      unless match.nil? or match.empty?
        final_path = match
        remainder.delete(path.first)
      else
        exists = false
      end     
    end
    
    # Returns the lsast piece of the path that matched the criteria, if the full path exists, and any remaining components of the
    # path
    return { :final_path => final_path, :exists => exists, :remainder => remainder }
  end  

  def collapse_functions(args)
    retval = ""
    cur_path = self.match(String.new)
    args.scan(/\/([^\[\/]*)(\[[^\]\[]*\])?+/).each do |path|
      cur_path = self.match(path.first, cur_path) unless cur_path.nil?
      ftest = "#{path.last}".match(/(last)\((.*)?\)(\+|\-)?(\d+)?/)
      unless ftest
        retval = retval + "/#{path.first}#{path.last}"
      else
        case ftest[1]
        when "last"
          test = 0
          test = cur_path.size unless cur_path.nil? or cur_path.empty?
          if ftest[3] and ftest[4]
            append = "[#{evaluate_expression(test, ftest[3], ftest[4].to_i)}]"
          else
            cur_path = [cur_path.last] if cur_path
            append = "[#{test}]"
          end
        else
          append = ""
        end
        retval = retval + "/#{path.first}#{append}"
      end
      cur_path = nil if cur_path.nil? or evaluate_match(cur_path,path.last).nil?
    end
    retval
  end
  
  def evaluate_expression(attr, expr, val)
    case expr
    when "=="
      return (attr == val)
    when "!="
      return (attr != val)
    when "<"
      return (attr.to_i < val.to_i)
    when ">"
      return (attr.to_i > val.to_i)
    when "<="
      return (attr.to_i <= val.to_i)
    when ">="
      return (attr.to_i >= val.to_i)
    when "+"
      return (attr + val)
    when "-"
      return (attr - val)
    end
    raise ArgumentError
  end

  
  def evaluate_match(match, args)
    return match unless args.is_a? String
    retval = match
    args.split('][').each do |evaluate|
      evaluate.gsub!(/^[\[]/, "").chomp!(']')
      parse = evaluate.match(/(#attribute\/)?(.*)?\ (==|!=|\<|\>|<=|>=)\ \"(.*)\"/)
      unless parse.nil? # Attribute or value evaluation
        if parse[1]
          retval = retval.select { |a| a if a.attributes.keys.include?(parse[2]) and
                                            evaluate_expression(a.attributes[parse[2]], parse[3], parse[4]) }
                                
        else
          retval = retval.select { |a| a if evaluate_expression(a.text, parse[3], parse[4]) }
        end
      else
        # Either a size check or a function
        if evaluate.match(/^(\[)?(\d+)(\])?+$/)  # All digits, must be an index variables
          index = evaluate.match(/^(\[)?(\d+)(\])?+$/)[2].to_i - 1
          return nil if (match.length < index) or !retval.include?(match[index])
          retval = [ match[index] ]
        else  # Function or bust!
          parse = evaluate.match(/(last)\((.*)?\)(\+|\-)?(\d+)?$/)
          return nil unless parse
        case parse[1]
        when 'last'
          if parse[3]
            return nil if parse[3] == '+'
            # Must be '-', right?  This isn't a dangerous assumption AT ALL
            raise ArgumentError unless parse[4]
            test = match[match.length() - parse[4].to_i]
            return nil unless retval.include?(match[match.length() - parse[4].to_i])
            retval = [match[match.length() - parse[4].to_i]]
          else
            return nil unless retval.include?(match.last)
              retval = [ match.last ]
            end
          end
        end
      end
    end
    return nil if retval.empty?
    retval
  end
end