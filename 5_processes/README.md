### Работаем с процессами

1) Реализовать "ps ax" с использованием /proc

Скрипт использует следующие файлы:
- /proc/* (с цифровыми именами) - для получения pid-ов
- /proc/\*/fd/0 - для tty
- /proc/\*/cmdline - для command line
- /proc/\*/stat - для статуса процесса

Если значение command line не было получено из /proc/\*/cmdline, считается, что это системный процесс, и тогда значение берется из /proc/\*/stat

2) Реализовать 2 конкурирующих процесса по CPU

Скрипт запускает 2 процесса сперва с одинаковыми nice по-умолчанию, затем с разными nice, и замеряет время выполнения

В качестве нагрузки запускается вычисление числа π с точностью 5000 знаков после запятой (задается параметром scale) при помощи утилиты bc

При отсутствии bc в системе скрипт выдает сообщение и завершает работу

Время замеряется командой "time"

Для адекватной работы на многоядерных системах процессы привязываются к одному ядру командой "taskset 1"

Вывод консоли:
```
Equal nice 0/0
15100 pts/2    R+     0:00 bc -l -q
15102 pts/2    R+     0:00 bc -l -q
Working...

real	0m31,742s
user	0m15,860s
sys	0m0,009s

real	0m31,881s
user	0m16,008s
sys	0m0,005s

Nice 0/+19
15183 (process ID) old priority 0, new priority 0
15185 (process ID) old priority 0, new priority 19
15183 pts/2    R+     0:00 bc -l -q
15185 pts/2    RN+    0:00 bc -l -q
Working...

real	0m16,209s
user	0m15,961s
sys	0m0,000s

real	0m31,979s
user	0m16,018s
sys	0m0,000s
```

### Литература
- [Занимательная математика командной строки](https://habr.com/ru/post/310566/)
- [How do I get the total CPU usage of an application from /proc/pid/stat?](https://stackoverflow.com/questions/16726779/how-do-i-get-the-total-cpu-usage-of-an-application-from-proc-pid-stat)
- [Структура /proc/pid/stat](https://web.archive.org/web/20130302063336/http://www.lindevdoc.org/wiki//proc/pid/stat)
