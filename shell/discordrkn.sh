#!/bin/bash
bashdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $bashdir/config.cfg

hook='curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data'
json=$(cat send.json)
#So POST to API executing by: $hook "$json" '$banhook'

#status codes
e0x0='Список сформирован (0x0)'
e0x1='Не найдены вчерашние списки. Новые будут сформированы завтра (0x1)'
e0x2='Ошибка загрузки сегодняшнего списка (0x2)'
e0x3='Нет изменений в списке за сутки (0x3)'

#Download data
    rm $shdir/old.txt
    mv $shdir/new.txt $shdir/old.txt
    wget -t 5 -T 300 -O $shdir/new.txt 'https://antifilter.download/list/domains.lst'

#Make Dirs
mkdir $shdir/msgbuff
mkdir $shdir/msgbuff/ban
mkdir $shdir/msgbuff/unban

#
#
#
#Code below is going to change so wait for new commits
#
#
#

#Git output marks new banned domains as + and the unbanned ones as - . So script remove the first line of git output and the first character '-' or '+' 
#grep removes first character of the line and tail removes first line of output

git diff $shdir/old.txt $shdir/new.txt | grep ^+ | sed 's/^.//' | tail -n +2 > $shdir/checkone.txt
	echo "**В СПИСОК ОГРАНИЧЕННЫХ РЕСУРСОВ СЕГОДНЯ ПОПАЛИ:**" > $shdir/bansite.txt
	echo "**$qdate**" >> $shdir/bansite.txt
	cat $shdir/checkone.txt >> $shdir/bansite.txt #New Banned Domains
	split -C 3900 $shdir/bansite.txt $shdir/msgbuff/ban/0x
git diff $shdir/old.txt $shdir/new.txt | grep ^- | sed 's/^.//' | tail -n +2 > $shdir/checktwo.txt
	echo "**Удалены из базы данных (Возможно, разблокированы):**" > $shdir/unbansite.txt
	echo "**$qdate**" >> $shdir/unbansite.txt
	cat $shdir/checktwo.txt >> $shdir/unbansite.txt #New Unbanned Domains
	split -C 3900 $shdir/unbansite.txt $shdir/msgbuff/unban/0x
    
#Set Vars
send=$jsdir/send.txt
channelid=$jsdir/var/cid
fieldname=$jsdir/var/name
new=$shdir/new.txt
old=$shdir/old.txt
banbytes=$(stat -c%s $shdir/checkone.txt)
bancount=$(wc -l < $shdir/checkone.txt)
unbanbytes=$(stat -c%s $shdir/checktwo.txt)
unbancount=$(wc -l < $shdir/checktwo.txt)
totalbanned=$(wc -l < $shdir/new.txt)

#check for errors
if [ -e $shdir/new.txt ]; then
    if [ -e $shdir/old.txt ]; then
        echo -e "$e0x0"
    else
        echo "$bancid" > $channelid
        echo -e "\n *$e0x1* $errorping" > $send
        $jsdir/send.sh
        isban=false
        isunban=false
        analytics=false
    fi
else
        echo "$bancid" > $channelid
        echo -e "\n *$e0x2* $errorping" > $send
        $jsdir/send.sh
        isban=false
        isunban=false
        analytics=false
fi

sleep 2
chmod 777 $shdir/*
sleep 2

#data collecting v1.0
#Date;banned;unbanned;total
if [ "$analytics" = true ]; then
    if [ "$banbytes" -le "2" ]; then
        bancount=0
    fi
    if [ "$unbanbytes" -le "2" ]; then
        unbancount=0
    fi
    echo -e "$csvdate ; $bancount ; $unbancount ; $totalbanned" >> $shdir/analytics.csv
fi

#Send List of new domain Bans
if [ "$isban" = true ]; then
echo "Заблокированые сегодня домены" > $fieldname
echo "$bancid" > $channelid
if [ "$banbytes" -le "2" ]; then
    if [ "$errorsend" = true ]; then
        echo -e "\n :orange_book: *В сегодняшнем списке нет новых заблокированых ресурсов!* $errorping" > $send
        $jsdir/send.sh && sleep 2
    else
        sleep 2
    fi
else
	for file1 in $shdir/msgbuff/ban/*
		do
		cat "$file1" > $send && $jsdir/sendembed.sh && sleep 2
		done
	echo -e "**:fire: Сегодня заблокировано доменов:__ $bancount __!** \n :no_entry_sign: Всего заблокировано:__ $totalbanned __" > $send
	$jsdir/send.sh && sleep 2
fi
fi

#Unban check
if [ "$isunban" = true ]; then
echo "Разблокированые сегодня домены" > $fieldname
echo "$unbancid" > $channelid
if [ "$unbanbytes" -le "2" ]; then
	if [ "$errorsend" = true ]; then
        echo -e "\n :orange_book: *Сегодня никого не разблокировали!* $errorping" > $send
        $jsdir/send.sh && sleep 2
    else
        sleep 2
    fi
else
    #Send Unban List
    for file2 in $shdir/msgbuff/unban/*
        do
        cat "$file2" > $send && $jsdir/sendembed.sh && sleep 2
        done
echo -e "**:large_blue_diamond: Сегодня разблокировано доменов:__ $unbancount __! :large_blue_diamond:**" > $send
$jsdir/send.sh && sleep 2
fi
fi
  
#Cleanup
rm $shdir/v2ray.zip
rm $shdir/checkone.txt
rm $shdir/checktwo.txt
rm $shdir/bansite.txt
rm $shdir/unbansite.txt
rm -rf $shdir/msgbuff/
