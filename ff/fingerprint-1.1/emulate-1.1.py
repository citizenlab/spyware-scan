# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('', 80))
s.listen(1)
while True:
    conn, addr = s.accept()
    data = conn.recv(1024)
    hex = data.encode('hex')
    print hex[0:16]
    if hex[0:16] == "0c00000040017300":
        print "VALID FINSPY HELLO"
        conn.recv(1024);
        conn.close();
    else:
        print "INVALID FINSPY HELLO"
        conn.close()
        break

s.close()
