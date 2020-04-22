# Current Time
date '+%I:%M'

# Calendar
cal_head=`cal | head -1`;
cal_tail_head=`cal -h | tail -7 | head -1`;
cal_tail=`cal -h | tail -6`;
today=`date "+%e"`;
echo "$cal_head";
echo "${cal_tail_head// / }";
echo "${cal_tail/${today}/\033[1;31m${today}\033[0m}";

pmset -g batt

ssid=`/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep " SSID" | cut -f 2 -d : | tr -d [:blank:]`
test $ssid && echo "Network:  $ssid"

internal=`ipconfig getifaddr en0`
test $internal && echo "Internal: $internal"

external=`curl -s ifconfig.me`
test $external && echo "External: $external"

# PS
ps ax -c -o command,%cpu,%mem -r | head -n 8 | tail -7;

