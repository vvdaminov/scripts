# !/bin/bash

# Источники:
# https://www.howtoforge.com/tutorial/ubuntu-postgresql-installation/

############################
# Предисловие
############################

# Для удобства установил расширение позволяющее открывать файлы и папки под root-ом правой клавишей мыши.
# sudo apt-get install nautilus-admin
# nautilus -q #Перезапуск

# Подготовка
############################
# выход в случае ошибок
set -e

# Подключаем файл с конфигурациоными пеерменными (формат имён cfg_*). Седержмое файла выполняется как команды. 
source ./tools_install.cfg
# Текущий путь
cur_path=$(pwd)

# Сохраняем пароль в переменную, чтобы не запрашивать его каждый раз.
read -s -p "Введите пароль для sudo: " sudoPW
echo ""

############################
# 1.Инсталляция
############################
#\e[32m \e[0m -зелёный цвет
echo "\e[32m1. Инсталляция.\e[0m"

# Обновляем репозитории
echo $sudoPW | sudo -S apt update

# Инсталляция пакетов PostgreSQL, phpPgAdmin. postgresql-contrib должен подтянуть необходимые Apache2, PHP и т.д.
echo $sudoPW | sudo -S apt -y install postgresql postgresql-contrib phppgadmin

echo "\e[32m1. Инсталляция завершена.\e[0m"

############################
# 2. Настройка пользователя Postgres
############################
echo "\e[32m2. Настройка пользователя Postgres.\e[0m"

# подключаемся к терминалу PostgreSQL
# postgres - пользователь по умолчанию сначала без пароля
# Назначаем пароль                         

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '"$cfg_pgsql_postgres_password"';"

# потом вручную желательно сменить \password (пароль не сохранится в списке команд)
# выходим из терминала PostgreSQL
# \q

echo "\e[32m2. Настройка завершена.\e[0m"

############################
# 3. Настройка Apache Web Server
############################
echo "\e[32m3. Настройка Apache Web Server.\e[0m"

# проверка на уществование файла конфигурации
file_phppgadmin_conf="/etc/apache2/conf-available/phppgadmin.conf"
if [ ! -f "$file_phppgadmin_conf" ]; then
  echo "Файл $file_phppgadmin_conf, не существует!"
else
  # Даём всем развешение на доступ, заменая строки настроек
  echo $sudoPW | sudo -S sed -i 's/^#Require local/Require local/g' $file_phppgadmin_conf
  echo $sudoPW | sudo -S sed -i 's/^Require local/Require local\nRequire all granted/g' $file_phppgadmin_conf
fi

echo "\e[32m3. Настройка завершена.\e[0m"

############################
# 4. Настройка phpPgAdmin
############################
echo "\e[32m4. Настройка phpPgAdmin.\e[0m"

file_config_inc_php="/etc/phppgadmin/config.inc.php"
if [ ! -f "$file_config_inc_php" ]; then
  echo "Файл $file_config_inc_php, не существует!"
else
  # Даём возможность логиниться пользователю postgres
  echo $sudoPW | sudo -S sed -i 's/$conf\[\x27extra_login_security\x27\] = true/$conf\[\x27extra_login_security\x27\] = false/g' $file_config_inc_php
fi

#Перезапустить службы
echo  $sudoPW | sudo -S systemctl restart postgresql
echo  $sudoPW | sudo -S systemctl restart apache2

echo "\e[32m4. Настройка завершена.\e[0m"

############################
# 5. Testing Postgres
############################
echo "\e[32m5. Тестирование Postgres.\e[0m"

# PostgreSQL работает на порту 5432, Apache2 - HTTP порт 80 

echo  $sudoPW | sudo -S ss -ltpan
echo "\e[32mPostgreSQL ообычно работает на порту 5432, Apache2 - HTTP порт 80\e[0m"

echo "\e[32m5. Тестирование завершено.\e[0m"
exit