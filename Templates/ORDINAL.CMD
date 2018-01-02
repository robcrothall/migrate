/* */
x = 2
say ordinal(x)
say ordinal(10)
return

ordinal:
     ord.  = 'th'
     ord.1 = 'st'
     ord.2 = 'nd'
     ord.3 = 'rd'
     arg num .
return num || ord.num
