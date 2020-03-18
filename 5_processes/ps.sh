#! /bin/bash

echo -e "PID\tTTY\tSTAT\tCOMMAND" # вывод заголовка
for proc_id in `ls /proc | egrep '[0-9]+' | sort -g`; do # перебор по pid
	if [ -L "/proc/$proc_id/fd/0" ]; then # получение tty
		proc_tty=`ls -l /proc/$proc_id/fd/0 | awk '{print $NF}' | sed 's/^\/dev\///'`
		if [[ $proc_tty =~ "null" ]] || [[ $proc_tty =~ "pipe" ]] || [[ $proc_tty =~ "socket" ]];then
			proc_tty="?"; # исключаем ненужное
		fi
	else
		proc_tty="?";
	fi
	if [ -f /proc/$proc_id/cmdline ]; then # значение command line
		proc_cmd=`cat /proc/$proc_id/cmdline | tr '\0' ' '` ;
	fi
	if [ -f /proc/$proc_id/stat ]; then # состояние процесса
		stat=`cat /proc/$proc_id/stat | sed 's/\(d*\) (\(.*\)) \(.\)\ \(.*\)/\1#\2#\3#/g'`
		proc_state=`echo $stat | awk -F '#' '{ print $3 }'`;
		# если command line не было найдено ранее, получаем здесь
		if [ -z "$proc_cmd" ]; then proc_cmd="[`echo $stat | awk -F '#' '{ print $2 }'`]"; fi; 
	fi
	echo -e "$proc_id\t$proc_tty\t$proc_state\t$proc_cmd";
done