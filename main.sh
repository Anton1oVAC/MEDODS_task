#!bin/bash

# аргумент
SERVER=$1


# Обработка арг
if [[ -z "$1" ]]; then
    SERVER=$(whoami)
else
    SERVER="$1"
fi

# Макс. длина арг
if [[ ${#SERVER} -gt 20 ]]; then
    echo "Ошибка: Максимум 20 символов" >&2
    exit 1
fi



LINK=https://raw.githubusercontent.com/GreatMedivack/files/master/list.out
FILE=${SERVER}.out

DATE=$(date +"%d_%m_%Y")

RUNNING_FILE=${SERVER}_${DATE}_running.out
FAILED_FILE=${SERVER}_${DATE}_failed.out
REPORT_FILE=${SERVER}_${DATE}_report.out



# Проверка формата url
if [[ ! "$LINK" =~ ^https:// ]]; then 
	echo "Ошибка: Не соответсвует формату" >&2
	exit 1
fi

# Проверка доступности url
if ! curl --output /dev/null --silent --head --fail "$LINK"; then
	echo "Ошибка: URL недоступен или несуществует"
	exit 1
fi

# загрузка данных и сохр. в файл
if curl --silent --fail "$LINK" --output "$FILE"; then
	if [[ -s "$FILE" ]]; then
		echo "Данные сохр в "$FILE""
		echo "Размер файла: $(wc -l < "$FILE") строк"
	else
		echo "Ошибка: файл пустой" >&2
		rm -rf "$FILE"
		exit 1
	fi
else
	echo "Ошибка при загрузке данных" >&2
	exit 1
fi 	


# Удаление постфиксов и распред. по статусу 
awk -v failed_file="$FAILED_FILE" -v running_file="$RUNNING_FILE" '
NR > 1 {
   	# Удаление постфикс вида -xxxxxxxxxx-xxxxxx
    service_name = $1
    sub(/-[a-zA-Z0-9]{8,10}-[a-zA-Z0-9]{5,6}$/, "", service_name)
    
    if ($3 == "Error" || $3 == "CrashLoopBackOff") {
        print service_name >> failed_file
    } 
    else if ($3 == "Running") {
        print service_name >> running_file
    }
}' "$FILE"


# Файл отчета
RUNNING_COUNT=$(wc -l < "$RUNNING_FILE")
FAILED_COUNT=$(wc -l < "$FAILED_FILE")
{
    echo "Работающие сервисы: $RUNNING_COUNT"
    echo "Сервисы с ошибками: $FAILED_COUNT"
    echo "Пользователь: $SERVER"
    echo "Дата: $DATE"
} > "$REPORT_FILE"

chmod 644 ${REPORT_FILE}


# Проверка на созд файлы
if [[ !  -s "$RUNNING_FILE" ]]; then
	echo "Предупреждение: Файл "$RUNNING_FILE" не создан!"
fi

if [[ !  -s "$FAILED_FILE" ]]; then
	echo "Предупреждение: Файл "$FAILED_FILE" не создан!"
fi 

if [[ ! -s "$REPORT_FILE" ]]; then
	echo "Предупреждение: Файл "$REPORT_FILE" не создан!"
fi


# Создание архива и перенос файлов в архив, удаление лишнего
if [[ ! -d "archives" ]]; then
	mkdir -p archives
else
	echo "Папка уже существует"
fi

ARCH_NAME=${SERVER}_${DATE}.zip

if [[ ! -f "archives/$ARCH_NAME" ]]; then
	zip archives/$ARCH_NAME "$FILE" "$RUNNING_FILE" "$FAILED_FILE" "$REPORT_FILE"
	echo "Архив создан"
	rm -rf *.out
else
	echo "Архив с именем $ARCHIVE_NAME уже существует"
	rm -rf *.out
fi