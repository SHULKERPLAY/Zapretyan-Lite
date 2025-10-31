#!/bin/bash
#Ver 1.17
bashdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $bashdir/config.cfg

#Set Vars
new=$shdir/new.txt
old=$shdir/old.txt
#status codes
e0x0='Список сформирован (0x0)'
e0x1='Не найдены вчерашние списки. Новые будут сформированы завтра (0x1)'
e0x2='Ошибка загрузки сегодняшнего списка (0x2)'
e0x3='Нет изменений в списке за сутки (0x3)'

#Download data
rm ${old:?}
mv $new $old
curl --insecure --output ${new:?} 'https://antifilter.download/list/domains.lst'

#Make Dirs
mkdir $shdir/msgbuff
mkdir $shdir/msgbuff/ban
mkdir $shdir/msgbuff/unban

#Git output marks new banned domains as + and the unbanned ones as - . So script remove the first line of git output and the first character '-' or '+' 
#grep removes first character of the line and tail removes first line of output

git diff $old $new | grep ^+ | sed 's/^.//' | tail -n +2 > $shdir/checkone.txt
	echo "**В СПИСОК ОГРАНИЧЕННЫХ РЕСУРСОВ СЕГОДНЯ ПОПАЛИ:**" > $shdir/bansite.txt
	echo "**$qdate**" >> $shdir/bansite.txt
	cat $shdir/checkone.txt >> $shdir/bansite.txt #New Banned Domains
	split -C 3900 $shdir/bansite.txt $shdir/msgbuff/ban/0x
git diff $old $new | grep ^- | sed 's/^.//' | tail -n +2 > $shdir/checktwo.txt
	echo "**Удалены из базы данных (Возможно, разблокированы):**" > $shdir/unbansite.txt
	echo "**$qdate**" >> $shdir/unbansite.txt
	cat $shdir/checktwo.txt >> $shdir/unbansite.txt #New Unbanned Domains
	split -C 3900 $shdir/unbansite.txt $shdir/msgbuff/unban/0x

#Count
banbytes=$(stat -c%s $shdir/checkone.txt)
bancount=$(wc -l < $shdir/checkone.txt)
unbanbytes=$(stat -c%s $shdir/checktwo.txt)
unbancount=$(wc -l < $shdir/checktwo.txt)
totalbanned=$(wc -l < $new)

#check for errors
if [ -e $new ]; then
    if [ -e $old ]; then
        echo -e "$e0x0"
    else
        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": "'"*$e0x1*"' '"$errorping"'","username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$banhook"
        isban=false
        isunban=false
        analytics=false
    fi
else
		curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": "'"*$e0x2*"' '"$errorping"'","username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$banhook"
        isban=false
        isunban=false
        analytics=false
fi

chmod 777 $shdir/*
sleep 1

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
    for bansend in "${banhook[@]}"; do
        if [ "$banbytes" -le "2" ]; then
            if [ "$errorsend" = true ]; then
                curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": ":orange_book: *В сегодняшнем списке нет новых заблокированых ресурсов!* '"$errorping"'","username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$bansend"
            else
                sleep 1
            fi
        else
            for file1 in $shdir/msgbuff/ban/*
                do
                embedlist=$(cat "$file1" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g') && curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": " ","embeds": [{"title": "Заблокированые сегодня домены","description": "'"$embedlist"'","color": 16753314,"footer": {"text": "Отправлено с помощью Заптетян Lite","icon_url": "'"$boticon"'"}}],"username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$bansend" && sleep 1
                done
            curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": "**:fire: Сегодня заблокировано доменов:__ '"$bancount"' __!** \n:no_entry_sign: Всего заблокировано:__ '"$totalbanned"' __","username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$bansend"
        fi
    done
fi

#Unban check
if [ "$isunban" = true ]; then
    for unbansend in "${unbanhook[@]}"; do
        if [ "$unbanbytes" -le "2" ]; then
            if [ "$errorsend" = true ]; then
                curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": ":orange_book: *:orange_book: *Сегодня никого не разблокировали!* '"$errorping"'","username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$unbansend"
            else
                sleep 1
            fi
        else
            #Send Unban List
            for file2 in $shdir/msgbuff/unban/*
                do
                embedlist=$(cat "$file2" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g') && curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": " ","embeds": [{"title": "Разблокированые сегодня домены","description": "'"$embedlist"'","color": 10669055,"footer": {"text": "Отправлено с помощью Заптетян Lite","icon_url": "'"$boticon"'"}}],"username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$unbansend" && sleep 1
                done
            curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"content": "**:large_blue_diamond: Сегодня разблокировано доменов:__ '"$unbancount"' __! :large_blue_diamond:**","username": "'"$botname"'","avatar_url": "'"$boticon"'"}' "$unbansend"
        fi
    done
fi
  
#Cleanup
rm $shdir/checkone.txt
rm $shdir/checktwo.txt
rm $shdir/bansite.txt
rm $shdir/unbansite.txt
rm -rf $shdir/msgbuff/
