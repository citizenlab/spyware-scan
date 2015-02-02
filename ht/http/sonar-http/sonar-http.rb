# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

require "base64"

def write_hit(line)
  File.open("hackingteam-hits.txt", 'a') {|f| f.write(line)}
end

i = 0
ARGF.each_line do |b|
  if i % 10000 == 0 then
    puts "Done #{i} lines"
  end

  b64 = b.split("\"")[11]
  next unless b64.size < 40000
  
  ban = Base64.strict_decode64(b64)
  
  if /HTTP\/1.1 (404 NotFound)?(400 BadRequest)?(500 InternalServerError)?\r\n(Connection: close\r\n)?Content-Type: text\/html\r\nContent-[lL]ength: [0-9]+\r\n(Connection: close\r\n)?(Server: Apache.*\r\n)?\r\n/ =~ ban and /Connection: close\r\n/ =~ ban then
    write_hit(b)
    # If it's a 200 (we have to subcase)
  elsif /HTTP\/1.1 200 OK\r\n(Connection: close\r\n)?Content-Type: text\/html\r\nContent-[lL]ength: [0-9]+\r\n(Connection: close\r\n)?(Server: Apache.*\r\n)?\r\n/ =~ ban and /Connection: close\r\n/ =~ ban then
    # If the 200 contains any redirection
    if /<meta http-equiv="refresh" content="0;url=http:\/\/[^\\]+">/ =~ ban then
      write_hit(b)
      # If the 200 contains Apache stuff
    elsif /Apache\/2.[0-9].[0-9] \(Unix\) OpenSSL\/1.0.0g Server/ =~ ban then
      write_hit(b)
    end
  end
  i += 1
end
