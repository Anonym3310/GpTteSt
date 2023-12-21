#!/bin/bash

# Функции rename_and_unzip_archives и process_directories здесь...


expand_path() {
    local path=$1
    if [ "${path:0:1}" = "~" ]; then
        path="$HOME/${path:1}"
    fi
    echo "$path"
}

# Функция для запроса пути с таймером
get_path_with_timer() {
    local input_prompt=$1
    echo "$input_prompt (автоматический выбор текущей директории через 60 секунд):"
    local input_path
    read -r -t 60 input_path
    if [ -z "$input_path" ]; then
        echo "Используется текущая директория."
        input_path="."
    fi
    input_path=$(expand_path "$input_path")  # Преобразуем путь
    echo "Выбран путь: $input_path"
    echo "$input_path"
}

# Функция для обработки архивов
rename_and_unzip_archives() {
    local source_dir=$(expand_path "$1")
    local destination_dir=$(expand_path "$2")

    echo "Переименование и распаковка архивов из $source_dir в $destination_dir"

    for file in "$source_dir"/*.zip; do
        if [ -f "$file" ]; then
            local original_name new_name new_path
            original_name=$(basename "$file")
            # Используем встроенную замену строк в bash вместо echo | sed
            new_name="${original_name#"${original_name%%[!0-9]*}"}"

            # Если файл с новым именем уже существует, добавляем случайную цифру к имени
            while [ -f "$source_dir/$new_name" ]; do
                local random_digit=$((RANDOM % 10))
                new_name="${new_name%.*}$random_digit.${new_name##*.}"
            done

            new_path="$source_dir/$new_name"
            mv "$file" "$new_path"

            local dir_name="${new_name%.*}"
            mkdir -p "$destination_dir/$dir_name"
            unzip -o "$new_path" -d "$destination_dir/$dir_name"
        fi
    done
}

# Функция для обработки папок
process_directories() {
    local dir_to_process=$(expand_path "$1")

    echo "Обработка папок в $dir_to_process"
    for parent_dir in "$dir_to_process"*/; do
        if [ -d "$parent_dir" ]; then
            for child_dir in "$parent_dir"*/; do
                if [ -d "$child_dir" ]; then
                    shopt -s dotglob
                    if [ "$(ls -A "$child_dir")" ]; then
                        mv "$child_dir"* "$parent_dir"
                    fi
                    shopt -u dotglob
                    rmdir "$child_dir" 2>/dev/null || echo "Не удалось удалить каталог: $child_dir"
                fi
            done
        fi
    done
}

# Пример использования:
# rename_and_unzip_archives "путь/к/исходной/директории" "путь/к/директории/назначения"
# process_directories "путь/к/директории/для/обработки"


# Функция определения путей
define_paths() {
    echo "Запрос пути к исходной директории для архивов..."
    local source_dir_for_archives=$(get_path_with_timer "Путь к исходной директории для архивов")

    echo "Запрос пути к директории для временных папок..."
    local temp_dir_path=$(get_path_with_timer "Путь к директории для временных папок")
    mkdir -p "$temp_dir_path"

    echo "Запрос пути к директории для обработанных папок..."
    local destination_dir_for_processed=$(get_path_with_timer "Путь к директории для обработанных папок")

    rename_and_unzip_archives "$source_dir_for_archives" "$temp_dir_path"
    process_directories "$temp_dir_path"
    mv "$temp_dir_path"/* "$destination_dir_for_processed"
    rmdir "$temp_dir_path"
}

# Запуск функции определения путей
define_paths
'''
