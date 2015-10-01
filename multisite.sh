#!/bin/bash
#----Serving Multiple Sites With Independent Domains

echo "SERVING MULTIPLE SITES WITH INDEPENDENT DOMAINS"
web_root="/var/www/html/"
drupal_root="$web_root/drupal7/"
drupal_setting="$drupal_root/sites/default/default.settings.php"
apache_site="/etc/apache2/sites-available/"
apache_en="/etc/apache2/sites-enabled/"
custLog="/var/log/apache2/"


COUNT=0
read -p " Enter Directory To Create :" multisite
read -p "You need stag or dev:" type
touch /tmp/$multisite
multisite_dir=`cp -r $drupal_root $web_root$multisite`
sub_domain="$web_root$multisite/sites/"
cp $sub_domain/example.sites.php $sub_domain/sites.php
SITE_DEFAULT="/var/www/html/$multisite/sites/default"
#----MAIN SITE---
read -p "MAIN SITE NAME:" MAIN_SITE
ln -s $SITE_DEFAULT $sub_domain\/$MAIN_SITE
cp $drupal_setting $SITE_DEFAULT/settings.php
mkdir -p $SITE_DEFAULT/files
chmod 777 $SITE_DEFAULT/files
chmod 777 $SITE_DEFAULT/settings.php
touch $SITE_DEFAULT/README.txt
#--------MAIN SITE DATABASE ---

MAINSITE_FILENAME=$(basename $MAIN_SITE )
MAINSITE_FILENAME_NO_EXTENSION=$(echo $MAINSITE_FILENAME | cut -d '.' -f1)
MAINSITE_NOW=$(date +"%d%b")
MAINSITE_DB_NAME=`echo $MAINSITE_FILENAME_NO_EXTENSION\_$MAINSITE_NOW`
MAINSITE_DB_USER=`echo $MAINSITE_FILENAME_NO_EXTENSION`
MAINSITE_DB_PASSWD=`echo $MAINSITE_FILENAME_NO_EXTENSION`
MAINSITE_DB_CREATE="CREATE DATABASE IF NOT EXISTS $MAINSITE_DB_NAME;"
MAINSITE_DB_GRANT="GRANT ALL ON *.* TO '$MAINSITE_DB_USER'@'localhost' IDENTIFIED BY '$MAINSITE_DB_PASSWD';"
MAINSITE_DB_FLUSH="FLUSH PRIVILEGES;"
MAINSITE_SQL="${MAINSITE_DB_CREATE}${MAINSITE_DB_GRANT}${MAINSITE_DB_FLUSH};"
mysql -uroot -padmin123 -e "$MAINSITE_SQL"
#---CREATING FILE--
touch $apache_site$MAIN_SITE.conf
ln -s $apache_site$MAIN_SITE.conf $apache_en$MAIN_SITE.conf
#-----MAIN SITE SITES-ENABLE
cat <<EOF>> $apache_site$MAIN_SITE.conf
  <VirtualHost *:80>
    ServerAdmin webmaster@localhost

   # -- nk. Name and alias added
    ServerName  www.$MAIN_SITE
     ServerAlias $MAIN_SITE *.$MAIN_SITE $type-$MAINSITE_FILENAME_NO_EXTENSION.gailabs.com
    DocumentRoot $web_root$multisite
    <Directory />
        Options FollowSymLinks
        AllowOverride All
    </Directory>
    <Directory $web_root$multisite>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All 
        Order allow,deny
        allow from all
    </Directory>

    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
    <Directory "/usr/lib/cgi-bin">
        AllowOverride All 
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Order allow,deny
        Allow from all
    </Directory>
#ErrorLog $custLog/\/$dom_name_error.log
#CustomLog $custLog/\/$dom_name_access.log combined

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn


    Alias /doc/ "/usr/share/doc/"
    <Directory "/usr/share/doc/">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Allow from 127.0.0.0/255.0.0.0 ::1/128
    </Directory>
#---------Line Added By Rajesh-----
<Directory $web_root$multisite>
 RewriteEngine on
  RewriteBase /
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_URI} !=/favicon.ico
  RewriteRule ^ index.php [L]
</Directory>
</VirtualHost>
EOF
echo "192.168.1.243 $type-$MAINSITE_FILENAME_NO_EXTENSION.gailabs.com" >>/etc/hosts
#---Entering SITES.PHP--
cat <<FILE01>>$sub_domain/sites.php
$sites["$type-$MAINSITE_FILENAME_NO_EXTENSION.gailabs.com"] = '$MAINSITE';
FILE01

#----DOMAIN CREATION-----
read -p "No of domain to create:" _nu
echo "Use the names "firstsite.com" and "secondsite.com" to distinguish"
while [ $COUNT -lt $_nu ]
do
read -p " domain name:" dom_name
echo " DOMAINS - $dom_name" &>>/tmp/$multisite
A="$sub_domain$dom_name"
mkdir $A
touch $sub_domain$dom_name/README.txt
cp $drupal_setting $A/settings.php
mkdir $A/files
chmod 777 $A/files
chmod 777 $A/settings.php
touch $apache_site$dom_name.conf
ln -s $apache_site$dom_name.conf $apache_en$dom_name.conf
#####  DATABASE START HERE------
FILENAME=$(basename $dom_name)
FILENAME_NO_EXTENSION=$(echo $FILENAME | cut -d '.' -f1)
NOW=$(date +"%d%b")
DB_NAME=`echo $FILENAME_NO_EXTENSION\_$NOW`
DB_USER=`echo $FILENAME_NO_EXTENSION`
DB_PASSWD=`echo $FILENAME_NO_EXTENSION`
DB_CREATE="CREATE DATABASE IF NOT EXISTS $DB_NAME;"
DB_GRANT="GRANT ALL ON *.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWD';"
DB_FLUSH="FLUSH PRIVILEGES;"
SQL="${DB_CREATE}${DB_GRANT}${DB_FLUSH};"
mysql -uroot -padmin123 -e "$SQL"
if [ $? = 0 ]
then
echo -e  "Sucess\nDb Created\n "
echo "Database:\"$DB_NAME\" User:\"$DB_USER\" Passwd:\"$DB_PASSWD\"" &>>/tmp/$multisite
else
echo "Failed To create database"
fi
#----DATABASE ENDS HERE----

cat <<EOF>> $apache_site$dom_name.conf
  <VirtualHost *:80>
    ServerAdmin webmaster@localhost

   # -- nk. Name and alias added
    ServerName  www.$dom_name
     ServerAlias $dom_name *.$dom_name $type-$FILENAME_NO_EXTENSION.gailabs.com
    DocumentRoot $web_root$multisite
    <Directory />
        Options FollowSymLinks
        AllowOverride All
    </Directory>
    <Directory $web_root$multisite>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All 
        Order allow,deny
        allow from all
    </Directory>

    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
    <Directory "/usr/lib/cgi-bin">
        AllowOverride All 
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Order allow,deny
        Allow from all
    </Directory>
#ErrorLog $custLog/\/$dom_name_error.log
#CustomLog $custLog/\/$dom_name_access.log combined

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn


    Alias /doc/ "/usr/share/doc/"
    <Directory "/usr/share/doc/">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride All
        Order deny,allow
        Deny from all
        Allow from 127.0.0.0/255.0.0.0 ::1/128
    </Directory>
#---------Line Added By Rajesh-----
<Directory $web_root$multisite>
 RewriteEngine on
  RewriteBase /
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_URI} !=/favicon.ico
  RewriteRule ^ index.php [L]
</Directory>
</VirtualHost>
EOF
##------------------------

#########
echo "192.168.1.243 $type-$FILENAME_NO_EXTENSION.gailabs.com" >>/etc/hosts
let "COUNT += 1"
done
 
