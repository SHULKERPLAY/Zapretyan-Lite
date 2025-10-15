#!/bin/bash
echo zapretyan-retest-lite v2
#Repeat today's send
echo detecting directory
bashdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo cleanup
. $bashdir/config.cfg
rm $shdir/checkone.txt
rm $shdir/checktwo.txt
rm $shdir/bansite.txt
rm $shdir/unbansite.txt
rm -rf $shdir/msgbuff/

rm $bashdir/new.txt
mv $bashdir/old.txt $bashdir/new.txt
echo done. Executing zapretyanlite.sh
$bashdir/zapretyanlite.sh
