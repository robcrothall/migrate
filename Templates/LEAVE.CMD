/* LEAVE.CMD */
rep = ''
do forever
     say 'Continue? (Yes/No)'
     pull rep .
     if abbrev('YES', rep) | abbrev('NO', rep)
          then leave
     say 'Please enter YES or NO'
end
