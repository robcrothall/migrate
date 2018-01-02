rem Place this in c:\tcpip\bin

ppp.exe com2 38400 mru 1500 rtscts modem 163.197.170.53:163.197.170.54 netmask 255.255.224.0 priority 1 restart silent proxyarp auth user dialback name dialback secret dialback idle 15 connect "slattach AT&F OK ATE0Q0S0=0V1X1&C1&D2 OK ATS0=2S7=30 OK"
