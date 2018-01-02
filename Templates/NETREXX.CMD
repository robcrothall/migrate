/* REXX */
/* Sample for RXLAN (C) RZplus GmbH 1993                  */
/* Installation: Put RXLAN.DLL Somewhere in your LIBPATH  */

if rxfuncquery( "RxNetInfo" ) then do
   if rxfuncadd( "RxNetInfo", "RxLAN", "RxNetInfo" ) then do
      signal failure
   end
end

say "Your userid is:" RxNetInfo( "userid" )
say "and your logged on to domain:" RxNetInfo( "domain" )


call rxfuncdrop( "RxNetInfo" )

