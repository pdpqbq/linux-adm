#!/bin/bash

scale=5000 # влияет на продолжительность вычислений

if [[ `which bc` = '' ]]; then
	echo BC utility not found. Please install from http://ftp.gnu.org/gnu/bc/ or \'apt install bc\' or \'yum install bc\' and run again
	exit
fi

echo "Equal nice 0/0"
time echo "scale=$scale; 4*a(1)" | taskset 1 bc -l -q 1>/dev/null & # процесс 1
time echo "scale=$scale; 4*a(1)" | taskset 1 bc -l -q 1>/dev/null & # процесс 2
pid12=`ps ax | grep "bc -l -q" | grep -v grep | awk '{ print $1 }'` # pid-ы процессов
pid1=`echo "$pid12" | head -n 1`
pid2=`echo "$pid12" | tail -n 1`
ps ax | grep "bc -l -q" | grep -v grep
echo Working...
while [[ `ps ax | grep "bc -l -q" | grep -v grep` != '' ]]; do
	sleep 3 # ожидание окончания работы
done

echo
echo "Nice 0/+19"
time echo "scale=$scale; 4*a(1)" | taskset 1 bc -l -q 1>/dev/null &
time echo "scale=$scale; 4*a(1)" | taskset 1 bc -l -q 1>/dev/null &
pid12=`ps ax | grep "bc -l -q" | grep -v grep | awk '{ print $1 }'`
pid1=`echo "$pid12" | head -n 1`
pid2=`echo "$pid12" | tail -n 1`
renice 0 $pid1
renice 19 $pid2
ps ax | grep "bc -l -q" | grep -v grep
echo Working...
while [[ `ps ax | grep "bc -l -q" | grep -v grep` != '' ]]; do
	sleep 3
done
