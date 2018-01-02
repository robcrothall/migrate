set -x

#
# first, run the trip test:

( cd ../trip; ../src/rexx testing )

#
# Then, run a rew of the demos:

sleep 5
echo 4 | ./rexx ../demo/hanoi.rexx
sleep 5
clear
./rexx ../demo/block.rexx
echo
./rexx ../demo/rexxcps.rexx
echo
