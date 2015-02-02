# Copyright (C) 2014 Bill Marczak.
# See the file 'LICENSE' for copying permission.

import socket
import sys

if len(sys.argv) < 3:
    print "Usage: python 1.1py ip port"
    sys.exit(-1)

THE_PORT = int(sys.argv[2])

ok1 = False
ok2 = False

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(15)
    s.connect((sys.argv[1], THE_PORT))
    s.send('\x0c\x00\x00\x00\x40\x01\x73\x00\x01\x02\x03\x04')
    data = s.recv(1500)
    sys.exit(-1)

except socket.timeout:
    ok1 = True
s.close()

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(15)
    s.connect((sys.argv[1], THE_PORT))
    s.send('\x0c\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff')
    data = s.recv(1500)
    if data == '':
        ok2 = True
    else:
        sys.exit(-1)

except socket.timeout:
    sys.exit(-1)
s.close()

if ok1 and ok2:
    print "Possible FinSpy: " + sys.argv[1]
