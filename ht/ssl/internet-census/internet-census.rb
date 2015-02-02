# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

require 'openssl'
require 'digest/md5'
require 'base64'

FILENAME = "hits-" + Time.now.to_i.to_s + ".txt"

def check_cert(cert)
  if cert.issuer.to_s.include? "RCS Certification Authority" or cert.issuer.to_s.include? "HT srl" then
    return true
  elsif cert.subject.to_s() == "/CN=server" and cert.issuer.to_s() == "/CN=default" then
    return true
  elsif cert.issuer.to_s().include? "/CN=System Certification Authority/O=Organization ltd" then
    return true
  else
    if cert.issuer.to_s().length == 15 and cert.subject.to_s().length == 15 and cert.serial = 1 then
      exts = Hash[cert.extensions.map {|e| [e.oid(), e.value]}]
      if exts["extendedKeyUsage"] == "TLS Web Client Authentication" and exts["authorityKeyIdentifier"] and exts["authorityKeyIdentifier"].match("/CN.*").to_s() == cert.issuer.to_s() then
        return true
      end
    end
  end
  return false
end

def dump_chain(ip, ts, packed)
  # i'm too lazy to read about this whole DER thing
  # and also, yolo
  match = /\x0b...(...)...0\x82/m.match(packed)
  cert_chain_len = match[1].unpack('H*')[0].to_i(16)
  i = match.end(0) - 5
  cert_num = 0
  while cert_chain_len > 0 and i+3 < packed.length do
    cert_len = packed[i,3].unpack('H*')[0].to_i(16)
    i += 3
    the_cert = packed[i,cert_len]
    datetime = Time.at(ts.to_i).utc.to_s.rpartition(" ")[0]
    begin
      cert = OpenSSL::X509::Certificate.new(the_cert)
      pem_cert = cert.to_pem.rstrip
      digest = Digest::MD5.hexdigest(pem_cert)
      File.open(digest+".pem", 'w') {|f| f.write(pem_cert)}
      hit_string = "#{datetime}; #{ip}; #{digest}"
      File.open(FILENAME, 'a') {|f| f.puts(hit_string)}
      puts hit_string
    rescue
      File.open(FILENAME, 'a') {|f| f.puts("#{datetime}; #{ip}; error")}
    end
    cert_chain_len = cert_chain_len - 3 - cert_len
    i += cert_len
    cert_num += 1
  end
end


dn = -1
ARGF.each_line do |line|
   dn += 1
   if dn %10000 == 0 then
     puts "Done #{dn} certificates"
   end
   spl = line.strip.split(/\s+/)

   ip = spl[0]
   ts = spl[1]
   cert = spl[3]

   # If the census didn't record a cert, skip
   next if cert == nil

   i = 0
   packed = ""
   while i < cert.length do
     if cert[i] == "=" then
       packed += [cert[i+1,2].to_i(16)].pack('C')
       i += 3
     else
       packed += cert[i]
       i += 1
     end
   end

   # i'm too lazy to read about this whole DER thing
   # and also, yolo
   match = /\x0b...(...)...0\x82/m.match(packed)
   if not match.nil? then
     cert_chain_len = match[1].unpack('H*')[0].to_i(16)
     i = match.end(0) - 5
     cert_num = 0
     while cert_chain_len > 0 and i+3 < packed.length do
       cert_len = packed[i,3].unpack('H*')[0].to_i(16)
       i += 3
       the_cert = packed[i,cert_len]
       begin
         cert = OpenSSL::X509::Certificate.new(the_cert)

         # if we get a hit on any cert in the chain, then
         # dump the entire chain and break out of this
         # loop, advancing to the next line in the file
         if check_cert(cert) then
           dump_chain(ip, ts, packed)
           break
         end

       rescue
         unless cert_len > the_cert.length then
           # don't really know what's going on here, but
           # swag
           puts "ERROR LOADING CERT!"
         end
       end

       cert_chain_len = cert_chain_len - 3 - cert_len
       i += cert_len
       cert_num += 1
     end
   end
end
