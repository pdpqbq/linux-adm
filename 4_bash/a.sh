#!/bin/bash

# параметры
max_ip=5
max_urls=50
log=access-4560-644067.log
mailto=root

# настройка
declare -a ip_list # ip
declare -a url_list # url
declare -a code_list # http code
declare -a error_list # http error
declare -i mark_count
declare -i mark_current
mark_str="##########"
lock=`basename $0 .sh`.lock # файл для мультизапуска
conf=`basename $0 .sh`.cfg # файл с количеством меток
msg=`basename $0 .sh`.msg # файл с сообщением
have_job=0 # если есть работа то 1

# защита от мультизапуска
if [ -f $lock ]; then exit; fi
trap 'rm $lock' EXIT
echo "$$" > $lock

parse() # разбор строки
{
	#echo $* | sed 's/^\(.*\) \(.*\) \(.*\) \[\(.*\)\] \"\(.*\)\" \(.*\) \(.*\) \"\(.*\)\" \"\(.*\)\"$/\1#\2#\3#\4#\5#\6#\7#\8#\9/g'
	log_line=`echo $* | sed 's/^\(.*\) \(.*\) \(.*\) \[\(.*\)\] \"\(.*\)\" \(.*\) \(.*\) \"\(.*\)\" \"\(.*\)\"$/\1#\4#\5#\6/g'`
	log_time=`echo $log_line | awk -F "#" '{ print $2 }'`
	log_ip=`echo $log_line | awk -F "#" '{ print $1 }'`
	log_url=`echo $log_line | awk -F "#" '{ print $3 }' | \\
									sed 's/ HTTP\/.\..$//; s/^GET //; s/^POST //; s/^HEAD //'` # удаление HTTP GET POST HEAD
	log_code=`echo $log_line | awk -F "#" '{ print $4 }'`
	#echo $log_ip, $log_time, $log_url, $log_code
	ip_list+=($log_ip) # заполнение массивов
	url_list+=("$log_url")
	code_list+=($log_code)
	if [[ $log_code =~ 4[0-9][0-9]  ]] || [[ $log_code =~ 50[0-9] ]] || [[ $log_code =~ 510 ]]; then error_list+=($log_code); fi
	if [ -z "$start_time" ]; then start_time=$log_time; fi # время начала, если не установлено
	end_time=$log_time # время окончания по текущей строке лога
	have_job=1;
}

#sort $log | uniq -c | awk '{print $2" "$1}' | head -n 3
if [ -f $conf ]; then read mark_count < $conf; else mark_count=0; fi # где закончили
mark_current=0

while read line; do
	if [ "$line" = "$mark_str" ]; then	mark_current+=1; fi # промотка файла
	if [[ $mark_current -eq $mark_count ]] && [[ "$line" != "$mark_str" ]]; then parse $line; fi;
done < `find . -name $log`

if [ $have_job -eq 1 ]; then
	echo -e "Time range: $start_time\n            $end_time\n" | tee $msg # вывод времени
	echo Top $max_ip IP addresses with max requests | tee -a $msg
	echo ${ip_list[@]} | tr ' ' '\n' | sort -R | uniq -c | sort -gr | head -n $max_ip | tee -a $msg # вывод ip
	echo | tee -a $msg
	echo Top $max_urls URLs with max requests | tee -a $msg # вывод адресов
	for url in "${url_list[@]}"; do echo "$url"; done | sort -R | uniq -c | sort -gr | head -n $max_urls | tee -a $msg
	echo | tee -a $msg
	echo List of HTTP codes | tee -a $msg
	echo ${code_list[@]} | tr ' ' '\n' | sort -R | uniq -c | sort -gr | tee -a $msg # вывод кодов
	echo | tee -a $msg
	echo List of HTTP errors | tee -a $msg
	if [ ! ${#error_list[@]} -eq 0 ]; then
		echo ${error_list[@]} | tr ' ' '\n' | sort -R | uniq -c | sort -gr | tee -a $msg # вывод ошибок
	else echo "      No errors" | tee -a $msg;
	fi
	echo | tee -a $msg
	echo $mark_str >> $log
	mark_count+=1 && echo $mark_count > $conf # сохранение кол-ва меток

else
	echo No new data | tee $msg # ничего нет
fi

cat $msg | mail -s "Access log" $mailto