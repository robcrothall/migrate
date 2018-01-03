#!/usr/bin/regina
/*  */
trace 'i';
Parse source a;
say a;
Parse Version ver
Say ver
address system 'ls' with output STEM REC.
Kount = REC.0;
say "Kount = " Kount;
DO I = 1 to Kount;
   If REC.I = '' then leave;
   say I REC.I;
End;
address system 'ls' with output LIFO '';
Do I = 1 by 1;
   parse pull REC
   If REC = '' then leave;
   say I REC;
End;
foo. = 'bar';
say foo.1 foo.2
foo.1 = 'baz';
say foo.1 foo.2 foo.joe

say "That's all, folks!";

