#!bin/bash

LINK=https://raw.githubusercontent.com/GreatMedivack/files/master/list.out
FILE=test.out

# 
ALPHABET='[^a-zA-Z]+'
NUMBER='[^0-9]+'

DATE=$(date +"%d_%m_%Y")

# параметр
SERVER=$1

RUNNING_FILE=${SERVER}_${DATE}_running.out
FAILED_FILE=${SERVER}_${DATE}_failed.out



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
		echo "Данные сохр в "$TEST""
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



# Удаление постфиксов + сохр готового результата
awk -v failed_file="$FAILED_FILE" -v running_file="$RUNNING_FILE" '
NR > 1 {
   	# Удаляем только постфикс вида -xxxxxxxxxx-xxxxxx в конце строки
    service_name = $1
    sub(/-[a-zA-Z0-9]{8,10}-[a-zA-Z0-9]{5,6}$/, "", service_name)
    
    if ($3 == "Error" || $3 == "CrashLoopBackOff") {
        print service_name >> failed_file
    } 
    else if ($3 == "Running") {
        print service_name >> running_file
    }
}' "$FILE"


# Проверка на созд файлы и они не пусты
if [[ !  -s "$RUNNING_FILE" ]]; then
	echo "Предупреждение: нету запущенных сервисов"
	touch $RUNNING_FILE
fi

if [[ !  -s "$FAILED_FILE" ]]; then
	echo "Предупреждение: нету неработающих сервисов"
	touch $FAILED_FILE
fi 


echo "Готово! Результаты сохранены в:"
echo "- $FAILED_FILE ($(wc -l < "$FAILED_FILE") сервисов с ошибками)"
echo "- $RUNNING_FILE ($(wc -l < "$RUNNING_FILE") работающих сервисов)"







