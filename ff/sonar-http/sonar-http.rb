# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

require "base64"

def write_finspy_hit(line)
  File.open("finfisher-hits.txt", 'a') {|f| f.write(line)}
end

i = 0
ARGF.each_line do |b|
  if i % 10000 == 0 then
    puts "Done #{i} lines"
  end
  
  b64 = b.split("\"")[11]
  next unless b64.size < 40000
  
  ban = Base64.strict_decode64(b64)
  
  # Check for FinSpy / Hallo Steffi (1.0)
  if /HTTP\/1.1 200 OK\r\nContent-Type: text\/html; charset=UTF-8\r\nContent-Length:12\r\n\r\nHallo Steffi/ =~ ban then
    write_finspy_hit(b)
  # Check for FinSpy / Forbidden (2.0)
  elsif /UTC\r\nServer: Apache\r\nVary: Accept-Encoding\r\nContent-Length: 204\r\nContent-Type: text\/html; charset=iso-8859-1\r\n\r\n/ =~ ban then
    write_finspy_hit(b)
  # Check for FinSpy / Blank (3.0)
  elsif /HTTP\/1.1 200 OK\r\nContent-Type: text\/html; charset=UTF-8\r\n\r\n\"/ =~ ban then
    write_finspy_hit(b)
  # Check for FinSpy / It Works! (4.0)
  elsif /HTTP\/1.1 200 OK\r\nServer: Apache\r\nDate: [^\\]+\r\nContent-Type: text\/html; charset=iso-8859-1\r\nContent-Length: 140\r\n\r\n/ =~ ban then
    write_finspy_hit(b)
  end
  i += 1
end
