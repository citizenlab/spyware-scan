# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

def write_hit(line)
  File.open("critical-io-hits.txt", 'a') {|f| f.write(line)}
  puts line
end

i = 0
Dir.foreach('.') do |item|
  next unless item.match("critical*.json")
  puts item
  File.open(item).each_line do |ban|
    if i % 10000 == 0 then
      puts "Done #{i} lines"
    end

    # Pick up any NotFounds, badrequests, or internalservererrors
    if /HTTP\/1.1 (404 NotFound)?(400 BadRequest)?(500 InternalServerError)?\\r\\n(Connection: close\\r\\n)?Content-Type: text\/html\\r\\nContent-[lL]ength: [0-9]+\\r\\n(Connection: close\\r\\n)?(Server: Apache.*\\r\\n)?\\r\\n/ =~ ban and /Connection: close\\r\\n/ =~ ban then
      write_hit(ban)
    # If it's a 200 (we have to subcase)
    elsif /HTTP\/1.1 200 OK\\r\\n(Connection: close\\r\\n)?Content-Type: text\/html\\r\\nContent-[lL]ength: [0-9]+\\r\\n(Connection: close\\r\\n)?(Server: Apache.*\\r\\n)?\\r\\n/ =~ ban and /Connection: close\\r\\n/ =~ ban then
    # If the 200 contains any redirection
      if /<meta http-equiv=\\\"refresh\\\" content=\\\"0;url=http:\/\/[^\\]+\\\">/ =~ ban then
        write_hit(ban)
      # If the 200 contains Apache stuff
      elsif /Apache\/2.[0-9].[0-9] \(Unix\) OpenSSL\/1.0.0g Server/ =~ ban then
        write_hit(ban)
      end
    end
    i+=1
  end
end
