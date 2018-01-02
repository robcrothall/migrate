/* QTIME.CMD - Use EHLLAPI to get date and time from VM system */
 session = 'A'
 call RxFuncAdd 'HLLAPI','SAAHLAPI','HLLAPISRV'
 rc = hllapi('Connect', session) if rc \= 0 then do
     say 'Did not connect to host RC='rc
     signal quit
 end

 rc = hllapi('Wait') if rc \= 0 then do
     say 'Host keyboard locked.'
     signal quit
 end

 rc = hllapi('Sendkey', '@C')
 rc = hllapi('Wait')
 rc = hllapi('Sendkey', 'CP Query Time @E')
 rc = hllapi('Wait')
 pos = hllapi('Search_ps', 'TIME IS ', 1)
 if pos=0 then do
     say 'Host could not process QUERY TIME command'
     signal quit
 end

 time = hllapi('Copy_ps_to_str', pos + length('TIME IS '), 8)
 say time
 rc = hllapi('Sendkey', '@C') rc = hllapi('Wait')

quit:
    call hllapi('disconnect')
    call hllapi('reset_system')
return
