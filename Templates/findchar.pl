#!/usr/local/bin/perl
#
# MODULE: mail2hd.pl 
# AUTHOR: Ron Shalhoup (ron@captech.com)
# PURPOSE: Generate html file from mail message and store in data directory.
#          File receives a unique name from fields parsed from mail header.
#

###########################################################################
#                  DEFAULTED CONFIGURATIONS                               #
###########################################################################

#$DATADIR = "/usr/local/etc/httpd/htdocs/helpdesk/data";
$DATADIR = "/home/httpd/html/helpdesk/data";

$MESSAGE_DELIM="^From[^:]";          # mail message delimiter.
$SUBJECT_FIELD="^Subject:[^:]";      # Subject line identifier.
$HEADER_BODY_DELIM="\n";             # Delimiter between mail header and body
$ALT_FROM_FIELD="^Really from:[^:]";
$LOCAL_DOM="mercury.crothall.co.za";               # The local domain
$HTTPD_USER="nobody";                 # User account running web server

$found_body_delimiter=0;

@mnths = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

while (<>) {

   # Look for blank line between mail header and body of message.
   if ( !$found_body_delimiter && /^$HEADER_BODY_DELIM/) {
      $found_body_delimiter=1;
   }

   # Searching mail header for address of sender and subject. 
   if ( !$found_body_delimiter ) {
      if (/$MESSAGE_DELIM/) {
         chop;
         (/$LOCAL_DOM/ && /$MESSAGE_DELIM<([\w\.\-]+)\@[\w\.\-]+>.*/) || 
         (/$LOCAL_DOM/ && /$MESSAGE_DELIM([\w\.\-]+)\@[\w\.\-]+\b.*/) ||
         /$MESSAGE_DELIM<([\w\.\-]+\@[\w\.\-]+)>.*/ || 
         /$MESSAGE_DELIM([\w\.\-]+\@[\w\.\-]+)\b.*/ ||
         /$MESSAGE_DELIM<([\w\.\-]+)>/ || 
         /$MESSAGE_DELIM([\w\.\-]+)/;
         $from_addr = $1;
         push(@hdr,"$_\n");
      } elsif ( /$SUBJECT_FIELD/ ) {
         chop;
         /$SUBJECT_FIELD(.*)$/;
         $subject = $1;
         push(@hdr,"$_\n");
      } elsif ((/^Date:/) || (/^CC:/)) {
         push(@hdr,$_);
      }
   } else {
      if ((substr($from_addr,0,length($HTTPD_USER)) eq $HTTPD_USER) && 
          /$ALT_FROM_FIELD/) {
         (/$LOCAL_DOM/ && /$ALT_FROM_FIELD([\w\.\-]+)\@[\w\.\-]+\b.*/) ||
         /$ALT_FROM_FIELD([\w\.\-]+\@[\w\.\-]+)\b.*/ ||
         /$ALT_FROM_FIELD([\w\.\-]+)/;
         $from_addr = $1;
      }
      push(@msg,$_);
   } 
}

$hdr = join( "", @hdr );   #The entire mail header is one string in $hdr
$msg = join( "", @msg );   #The entire message is one string in $msg

# Get unique CallTrack ID and increment.
open(CNTFILE, "<$DATADIR/.count.txt") || die "Unable to open .count.txt";
$count = <CNTFILE>;
chop($count);
close(CNTFILE);
$count++;
open(CNTFILE, ">$DATADIR/.count.txt") || die "Unable to open .count.txt";
print CNTFILE "$count\n";
close(CNTFILE);

if (!defined $subject) {
    $subject = "No Subject";
}

# Eliminate characters meaningful to the OS from the subject field.
$desc = $subject;
$desc =~ tr/ /_/;
$desc =~ tr/./,/;
$desc =~ s/\//,/g;
$desc =~ s/[\[\]\|\?\*#<>"~`';]//g;

# Since "." is used as a field separator in filename, substitute "__"
# for "." for file storage.
$from_addr =~ s/\./__/g;

# This is done to prevent the system from repeatedly mail to itself.
# Messages sent from the system appear to be from the user running the
# web server.
#if ($from_addr eq $HTTPD_USER) { $from_addr = "nobody"; }
if ($from_addr eq $HTTPD_USER) { $from_addr = "root"; }

($mday,$mon) = (localtime(time))[3,4];
$date = "$mnths[$mon]_$mday";

# Generate html-formatted file from mail message.
$calltrack_file = "$desc.$from_addr.$count.$date.html";
open(CTFILE, ">$DATADIR/$calltrack_file") || 
    die "Unable to open $DATADIR/$calltrack_file\n";

print CTFILE <<End_of_Header;

<HTML><HEAD><TITLE>$count. $subject ($from_addr)</TITLE></HEAD>
<BODY BGCOLOR="#FFFFFF">
<H3>
<PRE>
$hdr
$msg
</PRE>
</BODY>
</HTML>

End_of_Header

close(CTFILE);
chmod(0444, "$DATADIR/$calltrack_file");

