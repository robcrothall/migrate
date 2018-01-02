echo off
echo ÿ
echo Rebuilding file database.  If this takes too long on your
echo system, see the section in MAX_OP.PRN on the "FB" utility.  This
echo process can be configured to run after the user logs off.
echo ÿ
fb %1 %2 %3
