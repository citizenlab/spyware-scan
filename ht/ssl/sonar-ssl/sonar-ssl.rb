# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

require 'openssl'
require 'digest/md5'
require 'base64'

FILENAME = "hits-" + Time.now.to_i.to_s + ".txt"

def print_hit(s, cert)
   pem_cert = cert.to_pem.rstrip
   digest = Digest::MD5.hexdigest(pem_cert)
   File.open(digest+".pem", 'w') {|f| f.write(pem_cert)}
   hit_string = "#{s[0]}; #{digest}"
   File.open(FILENAME, 'a') {|f| f.puts(hit_string)}
#   puts hit_string
   puts "#{s[0]}"
end

i = 0
ARGF.each_line do |line|
   if i %10000 == 0 then
     puts "Done #{i} certificates"
   end
   s = line.split(",")

   begin
      cert = OpenSSL::X509::Certificate.new(Base64.decode64(s[1]))
   rescue
      next
   end

   if cert.issuer.to_s.include? "RCS Certification Authority" or cert.issuer.to_s.include? "HT srl" then
      print_hit(s, cert)
   elsif cert.subject.to_s() == "/CN=server" and cert.issuer.to_s() == "/CN=default" then
      print_hit(s, cert)
   elsif cert.issuer.to_s().include? "/CN=System Certification Authority/O=Organization ltd" then
      print_hit(s, cert)
   else
     # This one occasionally yields false positives
     if cert.serial = 1 then
         exts = Hash[cert.extensions.map {|e| [e.oid(), e.value]}]
         if exts["extendedKeyUsage"] == "TLS Web Client Authentication" and exts["authorityKeyIdentifier"] and exts["authorityKeyIdentifier"].match("/CN.*").to_s() == cert.issuer.to_s() then
            print_hit(s, cert)
         end
      end
   end

   i += 1
end
