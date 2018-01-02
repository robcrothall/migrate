#ifndef lint
static char *RCSid = "$Id: builtin.c,v 1.14 1993/05/10 06:12:40 anders Exp anders $";
#endif

/*
 *  The Regina Rexx Interpreter
 *  Copyright (C) 1992-1994  Anders Christensen <anders@pvv.unit.no>
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public
 *  License along with this library; if not, write to the Free
 *  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include "rexx.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <time.h>
#include <stdio.h>
#include <assert.h>

#ifdef SunKludges
double pow( double, double ) ;
#endif

#define UPPERLETTER(a) ((((a)&0xdf)>='A')&&(((a)&0xdf)<='Z'))
#define NUMERIC(a) (((a)>='0')&&((a)<='9'))

int contained_in( char *first, char *fend, char *second, char *send )
{
   for (; (first<fend)&&(isspace(*first)); first++) ;
   for (; (second<send)&&(isspace(*second)); second++) ;
   
   for (; (first<fend); ) 
   {
      for (; (first<fend)&&(!isspace(*first)); first++, second++)
         if ((*first)!=(*second))
            return 0 ;

      if ((second<send)&&(!isspace(*second)))
         return 0 ;

      if (first==fend)
         return 1 ;

      for (; (first<fend)&&(isspace(*first)); first++) ;
      for (; (second<send)&&(isspace(*second)); second++) ;
   }

   return 1 ;
}



streng *std_wordpos( paramboxptr parms )
{
   streng *seek, *target ;
   char *sptr, *tptr, *end, *send ;
   int start=1, res ;

   checkparam( parms, 2, 3 ) ;
   seek = parms->value ;
   target = parms->next->value ;
   if (param(parms,3))
      start = atopos(parms->next->next->value) ;

   end = target->value + Str_len(target) ;
   /* Then lets position right in the target */
   for (tptr=target->value; isspace(*tptr) && (tptr<end); tptr++) ;
   for (res=1; (res<start); res++) 
   {   
      for (; (tptr<end)&&(!isspace(*tptr)); tptr++ ) ;
      for (; (tptr<end) && isspace(*tptr); tptr++ ) ;
   }

   send = seek->value + Str_len(seek) ;
   for (sptr=seek->value; (sptr<send) && isspace(*sptr); sptr++) ;
   if (sptr<send)
      for ( ; (sptr<send)&&(tptr<end); )
      {
         if (contained_in( sptr, send, tptr, end ))
            break ;
   
         for (; (tptr<end)&&(!isspace(*tptr)); tptr++) ;
         for (; (tptr<end)&&(isspace(*tptr)); tptr++) ;
         res++ ;
      }

   if ((sptr>=send)||((sptr<send)&&(tptr>=end)))
      res = 0 ;

   return int_to_streng( res ) ;
}


streng *std_wordlength( paramboxptr parms )
{
   int i, number ;
   streng *string ;
   char *ptr, *end ;

   checkparam( parms, 2, 2 ) ;
   string = parms->value ;
   number = atopos(parms->next->value) ;

   end = (ptr=string->value) + Str_len(string) ;
   for (; (ptr<end) && isspace(*ptr); ptr++) ;
   for (i=0; i<number-1; i++)
   {
      for (; (ptr<end)&&(!isspace(*ptr)); ptr++) ;
      for (; (ptr<end)&&(isspace(*ptr)); ptr++ ) ;
   }

   for (i=0; (((ptr+i)<end)&&(!isspace(*(ptr+i)))); i++) ;
   return (int_to_streng(i)) ;
}



streng *std_wordindex( paramboxptr parms ) 
{
   int i, number ;
   streng *string ;
   char *ptr, *end ;

   checkparam( parms, 2, 2 ) ;
   string = parms->value ;
   number = atopos( parms->next->value ) ;

   end = (ptr=string->value) + Str_len(string) ;
   for (; (ptr<end) && isspace(*ptr); ptr++) ;
   for (i=0; i<number-1; i++) {
      for (; (ptr<end)&&(!isspace(*ptr)); ptr++) ;
      for (; (ptr<end)&&(isspace(*ptr)); ptr++) ;
   }

   return ( int_to_streng( (ptr<end) ? (ptr - string->value + 1 ) : 0) ) ;
}


streng *std_delword( paramboxptr parms ) 
{
   char *rptr, *cptr, *end ;
   streng *string ;
   int length=(-1), start, i ; 

   checkparam( parms, 2, 3 ) ;
   string = Str_dup(parms->value) ;
   start = atopos( parms->next->value ) ;
   if ((parms->next->next)&&(parms->next->next->value))
      length = atozpos(parms->next->next->value) ;
   
   end = (cptr=string->value) + Str_len(string) ;
   for (; (cptr<end) && isspace(*cptr); cptr++ ) ;
   for (i=0; i<(start-1); i++)
   {
      for (; (cptr<end)&&(!isspace(*cptr)); cptr++) ;
      for (; (cptr<end) && isspace(*cptr); cptr++) ;
   }
   
   rptr = cptr ;
   for (i=0; (i<(length))||((length==(-1))&&(cptr<end)); i++)
   {
      for (; (cptr<end)&&(!isspace(*cptr)); cptr++ ) ;
      for (; (cptr<end) && isspace(*cptr); cptr++ ) ;
   }
      
   for (; (cptr<end);)
   {
      for (; (cptr<end)&&(!isspace(*cptr)); *(rptr++) = *(cptr++)) ;
      for (; (cptr<end) && isspace(*cptr); *(rptr++) = *(cptr++)) ;
   }

   string->len = (rptr - string->value) ;
   return string ;
}


streng *std_xrange( paramboxptr parms )
{
   int start=0, stop=0xff, i, length ;
   streng *result ;

   checkparam( parms, 0, 2 ) ;
   if (parms->value)
      start = (unsigned char) getonechar( parms->value ) ;
   
   if ((parms->next)&&(parms->next->value))
      stop = (unsigned char) getonechar( parms->next->value ) ;

   length = stop - start + 1 ;
   if (length<1)
      length = 256 + length ; 

   result = Str_make( length ) ;
   for (i=0; (i<length); i++) 	
   {
      if (start==256)
        start = 0 ;
      result->value[i] = (char) start++ ;
   }
/*    result->value[i] = (char) stop ; */
   result->len = i ;

   return result ;
}


streng *std_lastpos( paramboxptr parms )
{
   int res=0, start, i, j, nomore ;
   streng *needle, *heystack ;

   checkparam( parms, 2, 3 ) ;
   needle = parms->value ;
   heystack = parms->next->value ;
   if ((parms->next->next)&&(parms->next->next->value))
      start = atopos( parms->next->next->value ) ;
   else
      start = Str_len( heystack ) ;

   nomore = Str_len( needle ) ;
   if (start>Str_len(heystack))
      start = Str_len( heystack ) ;

   if (nomore>start) 
      res = 0 ;
   else if (nomore==0)
      res = start ;
   else 
      for (i=start-nomore ; i>=0; i-- )
      { 
         for (j=0; (j<=nomore)&&(needle->value[j]==heystack->value[i+j]);j++) ;
         if (j>=nomore)
         {
            res = i + 1 ;
            break ;
         }
      }

   return (int_to_streng(res)) ;
}



streng *std_pos( paramboxptr parms )
{
   int start = 1, res ;
   streng *needle, *heystack ;
   checkparam( parms, 2, 3 ) ;

   needle = parms->value ;
   heystack = parms->next->value ;
   if ((parms->next->next)&&(parms->next->next->value))
      start = atopos( parms->next->next->value ) ;

   if (((!needle->len)&&(!heystack->len)) || (start>heystack->len))
      res = 0 ;
   else
   {
      res = bmstrstr(heystack, start-1, needle) + 1 ;
   }

   return (int_to_streng( res ) ) ;
}



streng *std_subword( paramboxptr parms )
{
   int i, length, start ;
   char *cptr, *eptr, *cend ;
   streng *string, *result ;

   checkparam( parms, 2, 3 ) ;
   string = parms->value ;
   start = atopos( parms->next->value ) ;
   if ((parms->next->next)&&(parms->next->next->value)) 
      length = atozpos( parms->next->next->value ) ;
   else
      length = -1 ;

   cptr = string->value ;
   cend = cptr + Str_len(string) ;
   for (i=1; i<start; i++) 
   {
      for ( ; (cptr<cend)&&(isspace(*cptr)); cptr++) ;
      for ( ; (cptr<cend)&&(!isspace(*cptr)); cptr++) ;
   }
   for ( ; (cptr<cend)&&(isspace(*cptr)); cptr++) ;

   eptr = cptr ;
   if (length>=0)
   {
      for( i=0; (i<length); i++ )
      {
         for (;(eptr<cend)&&(isspace(*eptr)); eptr++); /* wount hit 1st time */
         for (;(eptr<cend)&&(!isspace(*eptr)); eptr++) ;
      }
   }
   else
      for(eptr=cend; (eptr>cptr)&&isspace(*(eptr-1)); eptr--) ;

   result = Str_make( eptr-cptr ) ;
   memcpy( result->value, cptr, (eptr-cptr) ) ;
   result->len = (eptr-cptr) ;

   return result ;
}



streng *std_symbol( paramboxptr parms )
{
   int type ;

   checkparam( parms, 1, 1 ) ;

   type = valid_var_symbol( parms->value ) ;
   if (type==SYMBOL_BAD)
      return Str_cre("BAD") ;

   if (type!=SYMBOL_CONSTANT) 
   {
      assert(type==SYMBOL_STEM||type==SYMBOL_SIMPLE||type==SYMBOL_COMPOUND);
      if (isvariable(parms->value))
         return Str_cre("VAR") ;
   }

   return Str_cre("LIT") ;
}

#ifdef TRACEMEM
struct envirlist {
   struct envirlist *next ;
   streng *ptr ;
} *first_envirvar=NULL ;


static void mark_envirvars( void )
{
   struct envirlist *ptr ;

   for (ptr=first_envirvar; ptr; ptr=ptr->next)
   {
      markmemory( ptr, TRC_STATIC ) ;
      markmemory( ptr->ptr, TRC_STATIC ) ;
   }
}

static void add_new_env( streng *ptr )
{
   struct envirlist *new ;

   new = Malloc( sizeof( struct envirlist )) ;
   new->next = first_envirvar ;
   new->ptr = ptr ;

   if (!first_envirvar)
      regmarker( mark_envirvars ) ;

   first_envirvar = new ;
}
#endif   



streng *std_value( paramboxptr parms )
{
   streng *string, *ptr ;
   streng *value=NULL, *env ;

   checkparam( parms,1,3 ) ;
   if (parms->next)
      value = (parms->next->value) ? (parms->next->value) : NULL ; 

   ptr = NULL ;
   if ((parms->next) && (parms->next->next) && (parms->next->next->value))
   {
      string = Str_ify( Str_dup( parms->value )) ;
      env = parms->next->next->value ;
      
      if ((Str_len(env)==6) && (!strncmp(env->value,"SYSTEM",6)))
      {
#ifdef VAXC
         ptr = vms_resolv_symbol( string, value, env ) ;
         ptr = ptr ;
#else
         char *val = getenv( string->value ) ;
         if (val) 
            ptr = Str_cre( val ) ;

         if (value)
#if defined(HAS_PUTENV) 
         {
#if defined(FIX_PROTOS) && defined(ultrix)
            void putenv(char*) ;
#endif
            streng *new = Str_make( Str_len(string) + Str_len(value) + 2 ) ;
            Str_cat( new, string ) ;
            Str_catstr( new, "=") ;
            Str_cat( new, parms->next->value ) ;
            new->value[Str_len(new)] = 0x00 ;

         /* Will generate warning under (e.g) Ultrix; don't bother! */
            putenv( new->value ) ;
         /* Note: we don't release this memory, because putenv might use */
         /* the area for its own purposes. */
         /* Free_string( new ) ; */  /* never to be used again */
#ifdef TRACEMEM
            add_new_env( new ) ;
#endif

         }       
#elif defined(HAS_SETENV)
            setenv(string->value, value->value, 1 ) ;
#else
         exiterror( ERR_SYSTEM_FAILURE ) ;
#endif /* HAS_PUTENV */
#endif /* VAXC */
      }
      else
         exiterror( ERR_INCORRECT_CALL ) ;

      Free( string ) ;
      if (ptr==NULL)
         ptr = nullstringptr() ;

      return ptr ;
   }

   string = parms->value ;
   ptr = get_it_anyway(string ) ;
   ptr = Str_dup( ptr ) ;
   if (value)
      setvalue( string, Str_dup(value) ) ;

   return ptr ;
}


streng *std_abs( paramboxptr parms )
{
   checkparam( parms,1,1 ) ;
   return str_abs( parms->value ) ;
}


streng *std_condition( paramboxptr parms ) 
{
   char opt='I' ;
   streng *result ;
   sigtype *sig ;
   trap *traps ;
   extern char *signalnames[] ;
   extern proclevel currlevel ;

   checkparam( parms, 0, 1 ) ;

   if (parms->value)
      opt = getoptionchar( parms->value, "CIDS" ) ;

   result = NULL ;
   sig = getsigs(currlevel) ;
   if (sig)
      switch (opt) 
      {
         case 'C':
            result = Str_cre( signalnames[sig->type] ) ;
            break ;

         case 'I':
            result = Str_cre( (sig->invoke) ? "SIGNAL" : "CALL" ) ;
            break ;
        
         case 'D':
            if (sig->descr)
               result = Str_dup( sig->descr ) ;
            break ;

         case 'S':
            traps = gettraps( currlevel ) ;
            if (traps[sig->type].delayed)
               result = Str_cre( "DELAY" ) ;
            else
               result = Str_cre( (traps[sig->type].on_off) ? "ON" : "OFF" ) ;
            break ;
 
         default:
            exiterror( ERR_INCORRECT_CALL ) ;
      }

   if (!result)
       result = nullstringptr() ;

   return result ;
}


streng *std_format( paramboxptr parms ) 
{
   streng *number ;
   int before=(-1), after=(-1) ;
   int esize=(-1), trigger=(-1) ;
   
   paramboxptr ptr ; 

   checkparam(parms,1,5) ;
   number = (ptr=parms)->value ;

   if ((ptr) && (ptr=ptr->next) && (ptr->value))
      before = atozpos( ptr->value ) ;

   if ((ptr) && (ptr=ptr->next) && (ptr->value))
      after = atozpos( ptr->value ) ;

   if ((ptr) && (ptr=ptr->next) && (ptr->value))
      esize = atozpos( ptr->value ) ;

   if ((ptr) && (ptr=ptr->next) && (ptr->value))
      trigger = atozpos( ptr->value ) ;

   return str_format( number, before, after, esize, trigger ) ;

 /*
   checkparam(parms,1,3) ;
   number = myatof(parms->value) ;

   if ((parms->next)&&(parms->next->value))
      before = atozpos(parms->next->value) ;
   if ((parms->next)&&(parms->next->next)&&(parms->next->next))
      after = atozpos(parms->next->next->value) ;

   retvalue = Str_make(4*SMALLSTR+STRHEAD) ;
   if ((before==0)&&(after==0)) 
      sprintf(retvalue->value,"%d",(int)number) ;
   else if (before==0) {
      sprintf(fmt,"%%.%df",after) ;
      sprintf(retvalue->value,fmt,number) ; }
   else if (after==0) {
      sprintf(fmt,"%%%d.12f",before+13) ;
      sprintf(retvalue->value,fmt,number) ; 
      for (i=strlen(retvalue->value)-1;(retvalue->value[i]=='0');
                                                 retvalue->value[i--]='\000') ;
      if (retvalue->value[i]=='.')  
         retvalue->value[i] = '\000' ; }
   else {
      sprintf(fmt,"%%%d.%df",before+after+1,after) ;
      sprintf(retvalue->value,fmt,number) ; }

   retvalue->len = strlen(retvalue->value) ;
   return retvalue ; 
 */
}



streng *std_overlay( paramboxptr parms )
{
   streng *newstr, *oldstr, *retval ;
   char padch=' ' ;
   int length, spot=0, oldlen, i, j, k ;
   paramboxptr tmpptr ;

   checkparam(parms,2,5) ;
   newstr = parms->value ;
   oldstr = parms->next->value ;
   length = Str_len(newstr) ;
   oldlen = Str_len(oldstr) ;
   if (parms->next->next) {
      tmpptr = parms->next->next ;
      if (parms->next->next->value) 
         spot = atopos(tmpptr->value) ;

      if (tmpptr->next) {
         tmpptr = tmpptr->next ;
         if (tmpptr->value)
            length = atozpos(tmpptr->value) ;
         if ((tmpptr->next)&&(tmpptr->next->value))
            padch = getonechar(tmpptr->next->value) ; } ; }
   
   retval = Str_make(((spot+length-1>oldlen)?spot+length-1:oldlen)) ;
   for (j=i=0;(i<spot-1)&&(i<oldlen);retval->value[j++]=oldstr->value[i++]) ;
   for (;j<spot-1;retval->value[j++]=padch) ;
   for (k=0;(k<length)&&(Str_in(newstr,k));retval->value[j++]=newstr->value[k++]) 
      if (i<oldlen) i++ ;

   for (;k++<length;retval->value[j++]=padch) if (oldlen>i) i++ ;
   for (;oldlen>i;retval->value[j++]=oldstr->value[i++]) ;

   retval->len = j ;
   return retval ;
}

streng *std_insert( paramboxptr parms )
{
   streng *newstr, *oldstr, *retval ;
   char padch=' ' ;
   int length, spot=0, oldlen, i, j, k ;
   paramboxptr tmpptr ;

   checkparam(parms,2,5) ;
   newstr = parms->value ;
   oldstr = parms->next->value ;
   length = Str_len(newstr) ;
   oldlen = Str_len(oldstr) ;
   if (parms->next->next) {
      tmpptr = parms->next->next ;
      if (parms->next->next->value) 
         spot = atozpos(tmpptr->value) ;

      if (tmpptr->next) {
         tmpptr = tmpptr->next ;
         if (tmpptr->value)
            length = atozpos(tmpptr->value) ;
         if ((tmpptr->next)&&(tmpptr->next->value))
            padch = getonechar(tmpptr->next->value) ; } ; }
   
   retval = Str_make(length+((spot>oldlen)?spot:oldlen)) ;
   for (j=i=0;(i<spot)&&(oldlen>i);retval->value[j++]=oldstr->value[i++]) ;
   for (;j<spot;retval->value[j++]=padch) ;
   for (k=0;(k<length)&&(Str_in(newstr,k));retval->value[j++]=newstr->value[k++]) ;
   for (;k++<length;retval->value[j++]=padch) ;
   for (;oldlen>i;retval->value[j++]=oldstr->value[i++]) ;
   retval->len = j ;
   return retval ;
}

   

streng *std_time( paramboxptr parms )
{
   extern nodeptr currentnode ;
   int hour ;
   time_t unow, now, rnow ;
   long usec, sec ;
   char *ampm, *retval ;
   char format='N' ;
   streng *answer ;
   extern proclevel currlevel ;
   struct tm *tmdata ;

   checkparam( parms, 0, 1 ) ;
   if ((parms)&&(parms->value))
      format = getoption(parms->value) ;

   retval = NULL ;
   if (currentnode->now) {
      now = currentnode->now ;
      unow = currentnode->unow ; }
   else  {
      getsecs(&now, &unow) ;
      currentnode->now = now ;
      currentnode->unow = unow ; }

   rnow = now ;
   if (unow>=(500*1000))
      now ++ ;

   tmdata = localtime(&now) ;
   switch (format) {
      case 'C':
         hour = tmdata->tm_hour ;
         ampm = (hour>11) ? "pm" : "am" ;
         if ((hour=hour%12)==0) 
            hour = 12 ;
         retval = Malloc(8+STRHEAD) ;
         sprintf(retval, "%d:%02d%s", hour, tmdata->tm_min, ampm) ;
         break ;

      case 'E':
      case 'R':
         sec = (currlevel->sec) ? rnow-currlevel->sec : 0 ;
         usec = (currlevel->sec) ? unow-currlevel->usec : 0 ; 
 
         if (usec<0)
         {
            usec += 1000000 ;
            sec-- ;
         }

         assert( usec>=0 && sec>=0 ) ;
         if (!currlevel->sec || format=='R') 
         {
            currlevel->sec = rnow ;
            currlevel->usec = unow ;
         }

         retval = Malloc(17 + STRHEAD) ;
         /*
          * We have to cast these since time_t can be 'any' type, and 
          * the format specifier can not be set to correspond with time_t,
          * then be have to convert it. Besides, we use unsigned format
          * in order not to generate any illegal numbers
          */
         if (sec)
            sprintf(retval,"%ld.%06lu", (long)sec, (unsigned long)usec ) ;
         else
            sprintf(retval,".%06lu", (unsigned long)usec ) ;
         break ;
 
      case 'H':
         sprintf(retval=Malloc(3 + STRHEAD), "%d", tmdata->tm_hour) ;
         break ;

      case 'J':
         sprintf(retval=Malloc(16), "%.06f", cpu_time()) ;
         break ;

      case 'L':
         retval = Malloc(16+STRHEAD) ;
         tmdata = localtime(&rnow) ;         
         sprintf(retval, "%02d:%02d:%02d.%06ld", tmdata->tm_hour,
                  tmdata->tm_min, tmdata->tm_sec, unow ) ;
         break ; 

      case 'M':
         retval = Malloc(5+STRHEAD) ;
         sprintf(retval, "%d", tmdata->tm_hour*60 + tmdata->tm_min) ;
         break ;

      case 'N':
         retval = Malloc(9+STRHEAD) ;
         sprintf(retval, "%02d:%02d:%02d", tmdata->tm_hour, 
                      tmdata->tm_min, tmdata->tm_sec ) ;
         break ;
     
      case 'S':
         retval = Malloc(6+STRHEAD) ;
         sprintf(retval, "%d", ((tmdata->tm_hour*60)+tmdata->tm_min)
                    *60 + tmdata->tm_sec) ;
         break ;

      default:
         exiterror(ERR_INCORRECT_CALL) ; }

   answer = (retval) ? Str_cre( retval ) : nullstringptr() ;
   Free( retval ) ;
   return answer ;
}

streng *std_date( paramboxptr parms )
{
   extern nodeptr currentnode ;
   char format = 'N' ;
   int length ;
   char *chptr, *retval ;
   streng *tstr ;
   struct tm *tmdata ;
   time_t now, unow, rnow ;
   extern char *months[], *WeekDays[] ;
   static char *fmt = "%02d/%02d/%02d" ;
   static char *iso = "%4d%02d%02d" ;

   checkparam( parms, 0, 1 ) ;
   if ((parms)&&(parms->value))
      format = getoption(parms->value) ;

   if (currentnode->now) {
      now = currentnode->now ;
      unow = currentnode->unow ; }
   else  {
      getsecs(&now, &unow) ;
      currentnode->now = now ;
      currentnode->unow = unow ; }

   retval = NULL ;
   rnow = now ;
   if (unow>=(500*1000))
      now ++ ;

   tmdata = localtime(&now) ;
   switch (format) {
      case 'B':
      case 'C':
         retval = Malloc(6+STRHEAD) ;
         length = tmdata->tm_yday + 1 +
                  (int)(((float)tmdata->tm_year-1)*365.25) + 365 ;
         sprintf(retval,"%d", format=='C' ? length : length+693595-1) ;
         break ;
      
      case 'D':
         retval = Malloc(4+STRHEAD) ;
         sprintf(retval, "%d", tmdata->tm_yday+1) ;
         break ;

      case 'E':
         retval = Malloc(9+STRHEAD) ;
         sprintf(retval, fmt, tmdata->tm_mday, tmdata->tm_mon+1, 
                              tmdata->tm_year) ;
         break ;
    
      case 'M':
         chptr = months[tmdata->tm_mon] ;
         retval = Malloc(length=strlen(chptr)+1+STRHEAD) ;
         memcpy(retval,chptr,length) ;
         break ;

      case 'N':
         retval = Malloc(12+STRHEAD) ;
         chptr = months[tmdata->tm_mon] ;
         sprintf(retval,"%d %c%c%c %4d", tmdata->tm_mday, chptr[0], chptr[1],
                           chptr[2], tmdata->tm_year+1900) ;
         /* Watch for the turn of the century, and in year 9999 ... */
         break ;
 
      case 'O':
         retval = Malloc(9+STRHEAD) ;
         sprintf(retval, fmt, tmdata->tm_year, tmdata->tm_mon+1, 
                           tmdata->tm_mday);
         break ;

      case 'S':
         retval = Malloc(9+STRHEAD) ;
         sprintf(retval, iso, tmdata->tm_year+1900, tmdata->tm_mon+1, 
                           tmdata->tm_mday) ;
         break ;

      case 'U':
         retval = Malloc(9+STRHEAD) ;
         sprintf(retval, fmt, tmdata->tm_mon+1, tmdata->tm_mday, 
                                tmdata->tm_year ) ;
         break ;

      case 'W':
         chptr = WeekDays[tmdata->tm_wday] ;
         retval = Malloc(length=strlen(chptr)+1+STRHEAD) ;
         memcpy(retval, chptr, length) ;
         break ;
   
      default:
         exiterror(ERR_INCORRECT_CALL) ; }
 
   tstr = ( retval ? Str_cre(retval) : nullstringptr() ) ;
   Free( retval ) ;
   return tstr ;
}
  

streng *std_words( paramboxptr parms )
{
   int space, i, j ;
   streng *string ;
   int send ;

   checkparam( parms, 1, 1 ) ;
   string = parms->value ;

   send = Str_len(string) ;
   space = 1 ;
   for (i=j=0;send>i;i++) {
      if ((!space)&&(isspace(string->value[i]))) j++ ;
      space = (isspace(string->value[i])) ; }
         
   if ((!space)&&(i>0)) j++ ;
   return( int_to_streng( j ) ) ;
}


streng *std_word( paramboxptr parms )
{
   streng *string, *result ;
   int i, j, finished, start, stop, number, space, slen ;

   checkparam( parms, 2, 2 ) ;
   string = parms->value ;
   number = atopos(parms->next->value) ;

   start = 0 ;
   stop = 0 ;
   finished = 0 ;   
   space = 1 ; 
   slen = Str_len(string) ;
   for (i=j=0;(slen>i)&&(!finished);i++) {
      if ((space)&&(!isspace(string->value[i]))) 
         start = i ;
      if ((!space)&&(isspace(string->value[i]))) {
         stop = i ;
         finished = (++j==number) ; }
      space = (isspace(string->value[i])) ; }

   if ((!finished)&&(((number==j+1)&&(!space)) || ((number==j)&&(space))))
   { 
      stop = i ;
      finished = 1 ; 
   }

   if (finished) 
   {
      result = Str_make(stop-start) ; /* problems with length */
      result = Str_nocat( result, string, stop-start, start) ;
      result->len = stop-start ;
   }
   else 
      result = nullstringptr() ;

   return result ;
}
      

   


streng *std_address( paramboxptr parms )
{
   extern proclevel currlevel ;

   checkparam( parms, 0, 0 ) ;
   update_envirs( currlevel ) ;
   return Str_dup( currlevel->environment ) ;
}


streng *std_digits( paramboxptr parms )
{
   extern proclevel currlevel ;

   checkparam( parms, 0, 0 ) ;
   return int_to_streng( currlevel->currnumsize ) ;
}


streng *std_form( paramboxptr parms )
{
   extern proclevel currlevel ;

   checkparam( parms, 0, 0 ) ;
   return Str_cre( numeric_forms[currlevel->numform] ) ;

}


streng *std_fuzz( paramboxptr parms )
{
   extern proclevel currlevel ;

   checkparam( parms, 0, 0 ) ;
   return int_to_streng( currlevel->numfuzz ) ;
}


streng *std_abbrev( paramboxptr parms ) 
{
   int length, answer, i ;
   streng *longstr, *shortstr ;

   checkparam( parms, 2, 3 ) ;
   longstr = parms->value ;
   shortstr = parms->next->value ;
   
   if ((parms->next->next)&&(parms->next->next->value))
      length = atozpos(parms->next->next->value) ;
   else
      length = Str_len(shortstr) ;

   answer = (Str_ncmp(shortstr,longstr,length)) ? 0 : 1 ;

   if ((length>Str_len(shortstr))||(Str_len(shortstr)>Str_len(longstr)))
      answer = 0 ;
   else
   {
      for (i=length; i<Str_len(shortstr); i++)
         if (shortstr->value[i] != longstr->value[i])
            answer = 0 ;
   }

   return int_to_streng( answer ) ;
}      


streng *std_queued( paramboxptr parms )
{
   checkparam( parms, 0, 0 ) ;
   return int_to_streng( lines_in_stack()) ;
}



streng *std_strip( paramboxptr parms )
{
   char option='B', padch=' ' ;
   streng *input ;
   int leading, trailing, start, stop ;

   checkparam( parms, 1, 3 ) ;
   if ((parms->next)&&(parms->next->value))
      option = (getonechar(parms->next->value)) & (0xdf) ;

   if ((parms->next)&&(parms->next->next)&&(parms->next->next->value))
      padch = getonechar(parms->next->next->value) ;

   if ((option!='B')&&(option!='T')&&(option!='L'))
      exiterror( 40 ) ;

   input = parms->value ;
   leading = ((option=='B')||(option=='L')) ;
   trailing = ((option=='B')||(option=='T')) ;

   for (start=0;(input->value[start]==padch)&&(leading);start++) ;
   for (stop=Str_len(input)-1;(input->value[stop]==padch)&&(trailing);stop--) ;
   if (stop<start)
      stop = start - 1 ;

   return Str_nocat(Str_make(stop-start+2),input,stop-start+1, start) ;
}



streng *std_space( paramboxptr parms )
{
   streng *retval, *string ;
   char padch=' ' ;
   int i, j, k, l, space=1, length=1, hole=0 ;

   checkparam( parms, 1, 3 ) ;
   if ((parms->next)&&(parms->next->value))
      length = atozpos(parms->next->value) ;   

   if ((parms->next)&&(parms->next->next)&&(parms->next->next->value))
      padch = getonechar(parms->next->next->value) ;

   string = parms->value ;
   for (i=0;Str_in(string,i);i++) {
      if ((space)&&(string->value[i]!=' ')) hole++ ;
      space = (string->value[i]==' ') ; }

   space = 1 ;
   retval = Str_make(i + hole*length ) ;
   for (j=l=i=0;Str_in(string,i);i++) {
      if (!((space)&&(string->value[i]==' '))) {
         if ((space=(string->value[i]==' ')))
            for (l=j,k=0;k<length;k++)
	       retval->value[j++] = padch ;
         else
            retval->value[j++] = string->value[i] ; } ; }

   retval->len = j ;
   if ((space)&&(j))
      retval->len -= length ;

   return retval ;
}


streng *std_arg( paramboxptr parms )
{
   int number=0, retval, tmpval ;
   char flag='\000' ;
   streng *value ;
   paramboxptr ptr ;
   extern proclevel currlevel ;

   checkparam( parms, 0, 2 ) ;
   if ((parms)&&(parms->value)) 
   {
      number = atopos( parms->value ) ;
      if (parms->next) 
      {
         flag = getoption(parms->next->value) ;
         if ((flag!='E')&&(flag!='O'))
            exiterror( 40 ) ; 
      }  
   }

   ptr = currlevel->args ;
   if (number==0) 
   {
      for (retval=0,tmpval=1; ptr; ptr=ptr->next, tmpval++) 
         if (ptr->value)
      	   retval = tmpval ;
      
      value = int_to_streng( retval ) ;
   }
   
   else 
   {
      for (retval=1;(retval<number)&&(ptr)&&(ptr=ptr->next);retval++) ;
      if (flag) 
      {
         retval = ((ptr)&&(ptr->value)) ;
         value = int_to_streng( (flag=='E')?retval:(!retval)) ;
      }
      else 
      {
         if ((ptr)&&(ptr->value))
            value = Str_dup(ptr->value) ;
         else
            value = nullstringptr() ; 
      }  
   }

   return value ;
}


#define LOGIC_AND 0
#define LOGIC_OR  1
#define LOGIC_XOR 2


static char logic( char first, char second, int ltype )
{
   switch (ltype) 
   {
      case ( LOGIC_AND ) : return ( first & second ) ;
      case ( LOGIC_OR  ) : return ( first | second ) ;
      case ( LOGIC_XOR ) : return ( first ^ second ) ;
      default : 
         exiterror( ERR_INTERPRETER_FAILURE ) ;
   }
   /* not reached, next line only to satisfy compiler */
   return 'X' ;
}
         

static streng *misc_logic( int ltype, paramboxptr parms )
{
   int length1, length2, i ;
   char padch ;
   streng *kill ;
   streng *pad, *outstr, *str1, *str2 ;

   checkparam( parms, 1, 3 ) ;
   str1 = parms->value ;

   str2 = (parms->next) ? (parms->next->value) : NULL ;
   if (str2 == NULL)
      kill = str2 = nullstringptr() ;
   else 
      kill = NULL ;

   if ((parms->next)&&(parms->next->next)) 
      pad = parms->next->next->value ; 
   else 
      pad = NULL ; 

   if (pad) 
   {
      padch = pad->value[0] ;
      if (Str_len(pad) != 1)
        exiterror( 40 ) ; 
   }
#ifdef lint
   else
      padch = ' ' ;
#endif

   length1 = Str_len(str1) ;
   length2 = Str_len(str2) ;
   if (length2 > length1 )
   { 
      streng *tmp ;
      tmp = str2 ;
      str2 = str1 ;
      str1 = tmp ;
   }

   outstr = Str_make( Str_len(str1) ) ;

   for (i=0; Str_in(str2,i); i++)
      outstr->value[i] = logic( str1->value[i], str2->value[i], ltype ) ;

   if (pad)
      for (; Str_in(str1,i); i++)
         outstr->value[i] = logic( str1->value[i], padch, ltype ) ;
   else 
      for (; Str_in(str1,i); i++)
         outstr->value[i] = str1->value[i] ;

   if (kill)
      Free_string( kill ) ;
   outstr->len = i ;
   return outstr ;
}


streng *std_bitand( paramboxptr parms )
{
   return misc_logic( LOGIC_AND, parms ) ;
}

streng *std_bitor( paramboxptr parms )
{
   return misc_logic( LOGIC_OR, parms ) ;
}

streng *std_bitxor( paramboxptr parms )
{
   return misc_logic( LOGIC_XOR, parms ) ;
}


streng *std_center( paramboxptr parms )
{
   int length, i, j, start, stop, chars ;
   char padch ;
   streng *pad, *str, *ptr ;

   checkparam( parms, 2, 3 ) ;
   length = atozpos( parms->next->value ) ;
   str = parms->value ;
   if (parms->next->next!=NULL)
      pad = parms->next->next->value ;
   else 
      pad = NULL ;

   chars = Str_len(str) ;
   if (pad==NULL)
      padch = ' ' ;
   else {
      padch = pad->value[0] ;
      if (Str_len(pad) != 1)
        exiterror( 40 ) ; }

   start = (chars>length) ? ((chars-length)/2) : 0 ;
   stop = (chars>length) ? (chars-(chars-length+1)/2) : chars ;

   ptr = Str_make( length ) ;
   for (j=0;j<((length-chars)/2);ptr->value[j++]=padch) ;
   for (i=start;i<stop;ptr->value[j++]=str->value[i++]) ;
   for (;j<length;ptr->value[j++]=padch) ;
 
   ptr->len = j ;
   assert((ptr->len<=ptr->max) && (j==length));

   return ptr ;
    
}

streng *std_sourceline( paramboxptr parms )
{
   extern sysinfo systeminfo ;
   static lineboxptr ptr=NULL, first=NULL ;
   static int lineno=0 ;
   int line ;
   streng *answer ;

   checkparam( parms, 0, 1 ) ;
   if (!parms->value) 
   {
      line = systeminfo->lastline->lineno ;
      answer = int_to_streng( line ) ;
   }

   else 
   {
      line = atopos( parms->value ) ;
      if (first != systeminfo->firstline) 
      {
         lineno = 1 ;
         first = ptr = systeminfo->firstline ; 
      }
      for (;(lineno<line);) 
      {
         if ((ptr=ptr->next)==NULL) exiterror( 40 ) ;
         lineno = ptr->lineno ; 
      }
      for (;(lineno>line);) 
      {
         if ((ptr=ptr->prev)==NULL) exiterror( 40 ) ;
         lineno = ptr->lineno ; 
      }

      answer = Str_dup(ptr->line) ;
   }
   return answer ;
}


streng *std_compare( paramboxptr parms )
{
   char padch ;
   streng *pad, *str1, *str2 ;
   int i, j, value ;

   checkparam( parms, 2, 3 ) ;
   str1 = parms->value ;
   str2 = parms->next->value ;
   if (parms->next->next)
      pad = parms->next->next->value ;
   else 
      pad = NULL ;

   if (!pad)
      padch = ' ' ;
   else 
      padch = getonechar(pad) ;

   value=i=j=0 ;
   while ((Str_in(str1,i))||(Str_in(str2,j))) {
      if (((Str_in(str1,i))?(str1->value[i]):(padch))!=
          ((Str_in(str2,j))?(str2->value[j]):(padch))) {
         value = (i>j) ? i : j ;
         break ; }
      if (Str_in(str1,i)) i++ ;
      if (Str_in(str2,j)) j++ ; }

   if ((!Str_in(str1,i))&&(!Str_in(str2,j)))
      value = 0 ;
   else
      value++ ;

   return int_to_streng( value ) ;
}      


streng *std_errortext( paramboxptr parms ) 
{
   checkparam( parms, 1, 1 ) ;
   return Str_cre( errortext(atopos(parms->value)) ) ;
}


streng *std_length( paramboxptr parms )
{
   checkparam( parms, 1, 1 ) ;
   return int_to_streng( Str_len( parms->value )) ;
}


streng *std_left( paramboxptr parms ) 
{
   int length, i ;
   char padch ;
   streng *pad, *str, *ptr ;

   checkparam( parms, 2, 3 ) ;
   length = atozpos( parms->next->value ) ;
   str = parms->value ;
   if (parms->next->next!=NULL)
      pad = parms->next->next->value ;
   else 
      pad = NULL ;

   if (pad==NULL)
      padch = ' ' ;
   else 
      padch = getonechar(pad) ;

   ptr = Str_make( length ) ;
   for (i=0;(i<length)&&(Str_in(str,i));i++)
      ptr->value[i] = str->value[i] ;

   for (;i<length;ptr->value[i++]=padch) ;
   ptr->len = length ;   
   
   return ptr ;
}

streng *std_right( paramboxptr parms ) 
{
   int length, i, j ;
   char padch ;
   streng *pad, *str, *ptr ;

   checkparam( parms, 2, 3 ) ;
   length = atozpos( parms->next->value ) ;
   str = parms->value ;
   if (parms->next->next!=NULL)
      pad = parms->next->next->value ;
   else 
      pad = NULL ;

   if (pad==NULL)
      padch = ' ' ;
   else 
      padch = getonechar(pad) ;

   ptr = Str_make( length ) ;
   for (j=0;Str_in(str,j);j++) ;
   for (i=length-1,j--;(i>=0)&&(j>=0);ptr->value[i--]=str->value[j--]) ;

   for (;i>=0;ptr->value[i--]=padch) ;
   ptr->len = length ;   
   
   return ptr ;
}


streng *std_verify( paramboxptr parms )
{
   char tab[256], ch ;
   streng *str, *ref ;
   int inv=0, start=0, res=0, i ;
   checkparam( parms,2,4 ) ;

   str = parms->value ;
   ref = parms->next->value ;
   if (parms->next->next) {
      if (parms->next->next->value) {
         ch = (*(parms->next->next->value->value)&0xdf) ;
         if (ch=='M')
            inv = 1 ;
         else if (ch!='N')
            exiterror( 40 ) ; }
      if (parms->next->next->next)
         start = atopos(parms->next->next->next->value)-1 ; }

   for (i=0;i<256;tab[i++]=0) ;
   for (i=0;Str_in(ref,i);tab[(unsigned char)(ref->value[i++])]=1) ;
   for (i=start;(Str_in(str,i))&&(!res);i++) {
      if (inv==(tab[(unsigned char)(str->value[i])]))
         res = i+1 ; }

   return int_to_streng( res ) ;
}
   
   

streng *std_substr( paramboxptr parms ) 
{
   int rlength, length, start, i, j ;
   char padch ;
   streng *pad=NULL, *str, *ptr ;
   paramboxptr bptr ;

   checkparam( parms, 2, 4 ) ;
   str = parms->value ;
   rlength = Str_len( str ) ;
   start = atopos( parms->next->value ) ;
   if ((bptr=parms->next->next)&&(parms->next->next->value)) 
      length = atozpos( parms->next->next->value ) ;
   else
      length = rlength-start+1 ;

   if ((bptr)&&(bptr->next)&&(bptr->next->value))
      pad = parms->next->next->next->value ; 
   

   if (pad==NULL)
      padch = ' ' ;
   else 
      padch = getonechar(pad) ;

   ptr = Str_make( length ) ;
   i = ((rlength>=start)?start-1:rlength) ;
   for (j=0;j<length;ptr->value[j++]=(Str_in(str,i))?str->value[i++]:padch) ;
   
   ptr->len = j ;
   return ptr ;
}



streng *std_max( paramboxptr parms )
{
   double largest, current ;
   paramboxptr ptr ;
   streng *result ;

   if (!(ptr=parms)->value)
      exiterror( ERR_INCORRECT_CALL ) ;

   largest = myatof( ptr->value ) ;

   for(;ptr;ptr=ptr->next)
      if ((ptr->value)&&((current=myatof(ptr->value))>largest))
         largest = current ;

   result = Str_make( sizeof(double)*3+7 ) ;
   sprintf(result->value, "%G", largest) ;
   result->len = strlen(result->value) ;
   return result ;
}
         


streng *std_min( paramboxptr parms )
{
   double smallest, current ;
   paramboxptr ptr ;
   streng *result ;

   if (!(ptr=parms)->value)
      exiterror( ERR_INCORRECT_CALL ) ;

   smallest = myatof( ptr->value ) ;

   for(;ptr;ptr=ptr->next)
      if ((ptr->value)&&((current=myatof(ptr->value))<smallest))
         smallest = current ;

   result = Str_make( sizeof(double)+7 ) ;
   sprintf(result->value, "%G", smallest) ;
   result->len = strlen(result->value) ;
   return result ;
}
         


streng *std_reverse( paramboxptr parms ) 
{
   streng *ptr ;
   int i, j ;

   checkparam( parms, 1, 1 ) ;

   ptr = Str_make(j=Str_len(parms->value)) ;
   ptr->len = j--  ;
   for (i=0;j>=0;ptr->value[i++]=parms->value->value[j--]) ;

   return ptr ;
}

streng *std_random( paramboxptr parms )
{
   int min=0, max=999, result ;
#ifdef HAS_RANDOM
   static int seed, sewed=0 ;
#else
   static unsigned int seed, sewed=0 ;
#endif

   if (sewed==0) {
      sewed = 1 ;
#ifdef HAS_RANDOM
      srandom(seed=(time((time_t *)0)%(3600*24))) ; }
#else
      srand(seed=(time((time_t *)0)%(3600*24))) ; }
#endif

   checkparam( parms, 0, 3 ) ;
   if (parms!=NULL) {
      if (parms->value)
         if (parms->next)
            min = atozpos( parms->value ) ;
         else
            max = atozpos( parms->value ) ;

      if (parms->next!=NULL) {
         if (parms->next->value!=NULL)
            max = atozpos( parms->next->value ) ;

         if (parms->next->next!=NULL) {
            seed = atozpos( parms->next->next->value ) ;
#ifdef HAS_RANDOM
	    srandom( seed ) ; 
#else
            srand( seed ) ;
#endif
         }  
      }  
   }

   if (min>max) 
      exiterror( ERR_INCORRECT_CALL ) ;

#ifdef HAS_RANDOM
   result = (random() % (max-min+1)) + min ;
#else
   result = (rand() % (max-min+1)) + min ;
#endif
   return int_to_streng( result ) ;
}
   

streng *std_copies( paramboxptr parms )
{
   streng *ptr ;
   int copies, i, length ;

   checkparam( parms, 2, 2 ) ;

   length = Str_len(parms->value) ;
   copies = atozpos(parms->next->value) * length ;
   ptr = Str_make( copies ) ;
   for (i=0;i<copies;i+=length)
      memcpy(ptr->value+i,parms->value->value,length) ;
    
   ptr->len = i ;
   return ptr ;
}


streng *std_sign( paramboxptr parms )
{
   double number ;
   
   checkparam( parms, 1, 1 ) ;

   number = myatof( parms->value ) ;
   return int_to_streng((number) ? ((number>0) ? 1 : -1) : 0 ) ;
}


streng *std_trunc( paramboxptr parms )
{
   int decimals=0 ;

   checkparam( parms, 1, 2 ) ;
   if ((parms->next)&&(parms->next->value))
      decimals = atozpos( parms->next->value ) ;

   return str_trunc( parms->value, decimals ) ;
}


streng *std_translate( paramboxptr parms )
{
   streng *iptr=NULL, *optr=NULL ;
   char padch=' ' ;
   streng *string, *result ;
   paramboxptr ptr ;
   int olength=0, i, ii ;

   checkparam( parms, 1, 4 ) ;

   string = parms->value ;
   if ((ptr=parms->next)&&(parms->next->value))
   {
      optr = parms->next->value ;
      olength = Str_len(optr) ;
   }

   if ((ptr)&&(ptr=ptr->next)&&(ptr->value))
   {
      iptr = ptr->value ;
   }

   if ((ptr)&&(ptr=ptr->next)&&(ptr->value))
      padch = getonechar(ptr->value) ;

   result = Str_make( Str_len(string) ) ;
   for (i=0; Str_in(string,i); i++) 
   {
      if ((!iptr)&&(!optr))
         result->value[i] = toupper(string->value[i]) ;
      else
      {
         if (iptr)
         {
            for (ii=0; Str_in(iptr,ii); ii++)
               if (iptr->value[ii]==string->value[i])
                  break ;
 
            if (ii==Str_len(iptr))
            {
               result->value[i] = string->value[i] ;
               continue ;
            }
         }
         else
            ii = ((unsigned char*)string->value)[i] ;

         if ((optr)&&(ii<olength))
            result->value[i] = optr->value[ii] ;
         else
            result->value[i] = padch ;
      }     
   }

   result->len = i ;
   return result ;
}


streng *std_delstr( paramboxptr parms )
{
   int i, j, length, sleng, start ;
   streng *string, *result ;

   checkparam( parms, 2, 3 ) ;

   sleng = Str_len((string = parms->value)) ;
   start = atozpos( parms->next->value ) ;

   if ((parms->next->next)&&(parms->next->next->value))
      length = atozpos( parms->next->next->value ) ;
   else
      length = Str_len( string ) - start + 1 ;

   if (length<0)
      length = 0 ;

   result = Str_make( (start+length>sleng) ? start : sleng-length ) ;
 
   for (i=j=0; (Str_in(string,i))&&(i<start-1); result->value[i++] = string->value[j++]) ;
   j += length ;
   for (; (j<=sleng)&&(Str_in(string,j)); result->value[i++] = string->value[j++] ) ;

   result->len = i ;
   return result ;
}

   

   

static int valid_hex_const( streng *str )
{
   char *ptr, *end_ptr ;
   int space_stat ;

   ptr = str->value ;
   end_ptr = ptr + str->len ;

   if ((end_ptr>ptr) && ((isspace(*ptr)) || (isspace(*(end_ptr-1)))))
   {
         return 0 ; /* leading or trailing space */
   }

   space_stat = 0 ;
   for (; ptr<end_ptr; ptr++)
   {
      if (isspace(*ptr))
      {
         if (space_stat==0) 
         {
            space_stat = 2 ;
         }
         else if (space_stat==1)
         {
            /* non-even number of hex digits in non-first group */
            return 0 ; 
         }
      }
      else if (isxdigit(*ptr))
      {
         if (space_stat)
           space_stat = ((space_stat==1) ? 2 : 1) ;
      }
      else
      {
         return 0 ; /* neither space nor hex digit */
      }
   }

   if (space_stat==1) 
   {
      /* non-even number of digits in last grp, which not also first grp */
      return 0 ;  
   }

   /* note: the nullstring is a valid hexstring */
   return 1 ;  /* a valid hex string */
}



streng *std_datatype( paramboxptr parms )
{
   streng *string, *result ;
   char option, ch, *cptr ;
   int res ; 
   
   checkparam( parms, 1, 2 ) ;

   string = parms->value ;

   if ((parms->next)&&(parms->next->value))
   {
      option = getoptionchar(parms->next->value,"ABLMNSUWX") ;
      res = 1 ;
      cptr = string->value ;
      if ((Str_len(string)==0)&&(option!='X'))
         res = 0 ;

      switch ( option )
      {
         case 'A':
            for (; cptr<Str_end(string); res = isalnum(*cptr++) && res) ;
            break ;

         case 'B':
            for (; cptr<Str_end(string); cptr++ ) 
               res &= ((*cptr=='0')||(*cptr=='1')) ;
            break ;

         case 'L':
            for (; cptr<Str_end(string); res = islower(*cptr++) && res ) ;
            break ;

         case 'M':
            for (; cptr<Str_end(string); res = isalpha(*cptr++) && res ) ;
            break ;
 
         case 'N':
            res = myisnumber(string) ;
            break ;

         case 'S':
            /* "... if string only contains characters that are valid
             *    in REXX symbols ...", so it really does not say that 
             *    string should be a valid symbol. Actually, according
             *    to this statement, '1234E+2' is a valid symbol, although
             *    is returns false from datatype('1234E+2','S')
             */
            for (; cptr<Str_end(string); cptr++)
            {
               ch = *cptr ;
               res &= ( ((ch<='z')&&(ch>='a')) || ((ch<='Z')&&(ch>='A'))
                          || ((ch<='9')&&(ch>='0')) || (ch=='.')
                          || (ch=='@') || (ch=='#') || (ch=='$') 
                          || (ch=='?') || (ch=='_') || (ch=='!')) ;
            }
            break ;
 
         case 'U':
            for (; cptr<Str_end(string); res = isupper(*cptr++) && res ) ;
            break ;
       
         case 'W':
            res = myiswnumber(string) ;
            break ; 

         case 'X':
            res = valid_hex_const( string ) ;
            break ;

         default:
            exiterror( ERR_INCORRECT_CALL ) ;
      }
      result = int_to_streng( res ) ;
   }
   else
   {
      cptr = ((string->len)&&(myisnumber(string))) ? "NUM" : "CHAR" ;
      result = Str_cre( cptr ) ;
   }

   return result ;
}


streng *std_trace( paramboxptr parms )
{
   extern proclevel currlevel ;
   extern sysinfo systeminfo ;
   streng *result, *string ;
   int ptr=0 ;

   checkparam( parms, 0, 1 ) ;

   result = Str_make( 3 ) ;
   if (systeminfo->interactive)
      result->value[ptr++] = '?' ;

   result->value[ptr++] = trace_stat ;
   result->len = ptr ;

   ptr = 0 ;
   if ((string=parms->value))
   {
      if (string->value[ptr]=='?')
      {
         ptr++ ;
         systeminfo->interactive = 1 ;
      }
 
      trace_stat = currlevel->tracestat = toupper(getonechar(string)) ;
   }

   return result ;
}
     

