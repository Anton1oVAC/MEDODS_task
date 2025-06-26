#!bin/bash

LINK=https://raw.githubusercontent.com/GreatMedivack/files/master/list.out

TEST=test.out

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
if curl --silent --fail "$LINK" --output "$TEST"; then
	if [[ -s "$TEST" ]]; then
		echo "Данные сохр в "$TEST""
		echo "Размер файла: $(wc -l < "$TEST") строк"
	else
		echo "Ошибка: файл пустой" >&2
		rm -rf "$TEST"
		exit 1
	fi
else
	echo "Ошибка при загрузке данных" >&2
	exit 1
fi 	
