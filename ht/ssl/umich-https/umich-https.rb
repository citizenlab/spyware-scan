# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

require 'fastest-csv'

def print_hit(line)
  File.open("hits.txt", 'a') {|f| f.puts(line)}
  puts line
end

i = 0
file = File.open("certificates.csv", "r")
while !file.eof
  line = file.readline.chomp

  if i %10000 == 0 then
    puts "Done #{i} certificates"
  end

  preline = line

  begin
    j = FastestCSV.parse_line(line)
    while j.length < 44
      line += "\\n" + file.readline.chomp
      j = FastestCSV.parse_line(line)
    end
    if j.length != 44 then
      puts "Parse err"
    end
  rescue
    puts "Parse err"
    next
  end

  issuer = j[6]
  subject = j[5]
  aki = j[20]
  ekui = j[19]
  serial = j[2]

  if not issuer or not subject or not serial then
    next
  end

  if issuer.include? "RCS Certification Authority" or issuer.include? "HT srl" then
    print_hit(line)
  elsif subject == "CN=server" and issuer == "CN=default" then
    print_hit(line)
  elsif issuer.include? "CN=System Certification Authority, O=Organization ltd" then
    print_hit(line)
  else
    if issuer.length == 14 and subject.length == 14 and serial == "1" then
      if ekui == "TLS Web Client Authentication" and aki and aki.match("/(CN.*)").captures()[0][0..13] == issuer then
        print_hit(line)
      end
    end
  end
  i += 1

end
