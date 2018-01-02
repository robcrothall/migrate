/* count- pipe filter to cut text from the input stream */
/* (c) burnvale Pty Ltd - dIon                          */
Parse Arg PipeArgs
PipeArgs = STRIP(TRANSLATE(PipeArgs))
Parse Var PipeArgs "-C" leftc1 "-" rightc Filec1
Parse Var PipeArgs "-C" leftc2 "." lengthc Filec2
Parse Var PipeArgs "-W" leftw1 "-" rightw Filew1
Parse Var PipeArgs "-W" leftw2 "." lengthw Filew2

If (POS("-C", PipeArgs) <> 0) Then Do
   Chars = 1
   Words = 0
   If (rightc <> "") Then Do
      left   = leftc1
      length = rightc - leftc1 + 1
      File   = Filec1
   End
   Else Do
      If (lengthc = "") Then lengthc = 1
      left   = leftc2
      length = lengthc
      File   = Filec2
   End
End
Else If (POS("-W", PipeArgs) <> 0) Then Do
   Words = 1
   Chars = 0
   If (rightw <> "") Then Do
      left   = leftw1
      length = rightw - leftw1 + 1
      File   = Filew1
   End
   Else Do
      if (lengthw = "") Then lengthw = 1
      left   = leftw2
      length = lengthw
      File   = Filew2
   End
End
Else Do
   Words = 0
   Chars = 0
   File   = ""
End

If (File = "") Then Do
   File = "STDIN"
End

If ((PipeArgs <> "?" | PipeArgs <> "") & (Words | Chars)) Then Do
   More = 1  
   Call on NotReady
   l = LINEIN(File)
   Do While (More)
      Select
         When (Chars) Then Do      
            Say SUBSTR(l, left, length)
         End
         When (Words) Then Do
            Say SUBWORD(l, left, length)
         End
      End
      l = LINEIN(File)
   End
End
Else Do /* Help section */
   Say "This CMD File is a pipe filter to cut words or characters..."
   Say "e.g TYPE CONFIG.SYS | CUT -C1-10 gives the chars in positions 1 to 10"
End

Return rc          

NotReady:
  More = 0
Return
