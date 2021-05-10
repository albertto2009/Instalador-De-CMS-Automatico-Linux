#!/bin/bash
#@Authors: Alberto Perez Hidalgo y Aurora Palma Perdigones
#@Comments: Script para crear servidor web y/o correo
#Menu: 
#1- Crear servidor web
#2- Crear servidor de mensajeria
#3- Realizar copia de seguridad de los archivos de configuracion
#4- Salir


## FUNCIONES

#comprobar que el script lo ejecute root
function soyroot(){
	if [ ! `whoami` == "root" ];then
		whiptail --title "Error" --msgbox "Solo superusuario puede ejecutar este script" 0 0
		exit 1
	fi
}
function menu(){
	menu=`whiptail --title "CREACION SERVIDOR WEB/EMAIL" --menu "Elija una de las siguientes opciones:" 0 0 4 1 "Crear Servidor web" 2 "Crear Servidor de Mensajeria" 3 "Realizar copia de seguridad de los archivos de configuracion" 4 "Salir" 3>&2 2>&1 1>&3`
	#Comprobamos si pulsa cancelar
	if [ $? -ne 0 ];then
		whiptail --msgbox "Ha pulsado cancelar, saliendo.." 0 0
		salir
	fi

	#Opciones del menu
	case $menu in
		#Crear Servidor web
		1)
			opcion1
		;;
		#Crear Servidor mensajeria
		2)
			opcion2
		;;
		#Crear copia de seguridad
		3)
			backup
		;;
		4)
			salir
		;;
	esac
}

function opcion1(){

	#Crear base de datos!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
	menu=`whiptail --title "CREACION DE SERVIDOR WEB" --menu "Elija uno de los siguientes CMS:" 0 0 4 1 "Wordpress" 2 "Drupal" 3 "Joomla" 4 "Volver al menu principal" 3>&2 2>&1 1>&3`
	case $menu in
		1)
			cms wordpress
		;;
		2)
			cms drupal
		;;
		3)
			cms joomla
		;;
	esac
}

function cms(){
#preguntar nombre
	nombreweb=`whiptail --title "Nombre web" --inputbox "Introduzca el nombre que tendra su web: (Ejemplo: www.miweb.net)" 0 0 3>&2 2>&1 1>&3`

#añadir nombre a /etc/hosts
	echo "127.0.0.1	"$nombreweb >> /etc/hosts
#quedarnos solo con el nombre de la web
	nombresitio=`echo $nombreweb | cut -d"." -f2`

#opciones wordpress, drupal, joomla
	sitioapache=$nombresitio".conf"
	case $1 in
	"wordpress")
		unzip /home/pi/Downloads/wordpress.zip -d /home/pi/Downloads/wordpress > /dev/null
		mkdir /var/www/$nombresitio
		cp -rf /home/pi/Downloads/wordpress/wordpress-4.6.1-es_ES/wordpress/* /var/www/$nombresitio/
		rm -rf /home/pi/Downloads/wordpress
		chown www-data:www-data /var/www/$nombresitio -R
		touch /etc/apache2/sites-available/$nombresitio.conf
		fichconf $nombreweb $nombresitio
		cd /etc/apache2/sites-available/
		a2ensite $sitioapache > /dev/null
		if [ $? -ne 0 ];then
			error
		fi
		service apache2 restart > /dev/null
		if [ $? -ne 0 ];then
			error
		fi
		
	;;
	"drupal")
		tar -xzvf /home/pi/Downloads/drupal-8.tar.gz -C /var/www/ > /dev/null
		mv /var/www/drupal-8.2.5 /var/www/$nombresitio
		chown www-data:www-data /var/www/$nombresitio -R
		touch /etc/apache2/sites-available/$nombresitio.conf
		fichconf $nombreweb $nombresitio
		cd /etc/apache2/sites-available/
		a2ensite $sitioapache > /dev/null
		if [ $? -ne 0 ];then
			error
		fi
		service apache2 restart > /dev/null
		if [ $? -ne 0 ];then
			error
		fi
	;;
	"joomla")
		mkdir /var/www/$nombresitio
		tar -xzvf /home/pi/Downloads/Joomla.tar.gz -C /var/www/$nombresitio > /dev/null
		chown www-data:www-data /var/www/$nombresitio -R
		touch /etc/apache2/sites-available/$nombresitio.conf
		fichconf $nombreweb $nombresitio
		cd /etc/apache2/sites-available/
		a2ensite $sitioapache > /dev/null
		if [ $? -ne 0 ];then
			error
		fi
		service apache2 restart > /dev/null
		if [ $? -ne 0 ];then
			error
		fi
	;;
	esac


}


#Funcion para configuar el archivo del sitio web
function fichconf(){
error="no"
#puerto a asignar
puerto=`whiptail --title "Puerto a asignar" --inputbox "Introduzca el puerto a asignar: (Ejemplo: 4040)" 0 0 3>&2 2>&1 1>&3`

if [ $puerto -lt 1024 ] || [ $puerto -gt 49151 ];then
	whiptail --title "Error" --msgbox "Debe introducir un puerto comprendido entre el rango 1024 y 49151" 0 0 
	error="yes"
fi

#comprobar que el puerto no se este usando ya para otro http
cat /etc/apache2/ports.conf | grep 'Listen '$puerto > /dev/null

if [ $? == 0 ];then
	whiptail --title "Error" --msgbox "El puerto introducido ya esta en uso. Vuelva a introducir otro puerto." 0 0 
	error="yes"
fi

#Añadir puerto a ports.conf
if [ $error != "yes" ];then

	echo Listen $puerto >> /etc/apache2/ports.conf 

	#configuracion archivo apache
	ruta="/etc/apache2/sites-available/$2.conf"	
	echo "ServerName 127.0.0.1" >> $ruta
	echo "<VirtualHost *:"$puerto">" >> $ruta
	echo "ServerName "$1 >> $ruta
	echo "DocumentRoot /var/www/"$2 >> $ruta
	echo "<Directory /var/www/"$2">" >> $ruta
	echo "DirectoryIndex index.php" >> $ruta
	echo "Options Indexes FollowSymLinks Multiviews" >> $ruta
	echo "AllowOverride None" >> $ruta
	echo "Order allow,deny" >> $ruta
	echo "allow from all" >> $ruta
	echo "</Directory>" >> $ruta
	echo "</VirtualHost>" >> $ruta
fi
	
}

function opcion2(){
#preguntar nombre
	nombreweb=`whiptail --title "Nombre web" --inputbox "Introduzca el nombre que tendra su webmail: (Ejemplo: www.miweb.net)" 0 0 3>&2 2>&1 1>&3`

#añadir nombre a /etc/hosts
	echo "127.0.0.1	"$nombreweb >> /etc/hosts
#quedarnos solo con el nombre de la web
	nombresitio=`echo $nombreweb | cut -d"." -f2`

	tar -xzvf /home/pi/Downloads/squirrelmail-webmail.tar.gz -C /var/www/ > /dev/null
	mv /var/www/squirrelmail-webmail-1.4.22 /var/www/$nombresitio
	chown www-data:www-data /var/www/$nombresitio -R
	touch /etc/apache2/sites-available/$nombresitio.conf
	fichconf $nombreweb $nombresitio
	cd /etc/apache2/sites-available/
	a2ensite $sitioapache > /dev/null
	if [ $? -ne 0 ];then
		error
	fi
	service apache2 restart > /dev/null
	if [ $? -ne 0 ];then
		error
	fi
}


function error(){
	whiptail --title "Error" --msgbox "Error, saliendo..." 0 0
	salir
}

function backup(){
	salir
}

function salir(){
	whiptail --yesno "¿Esta seguro de salir de la aplicacion?" 0 0
	if [ $? == 0 ];then
		exit 0
	fi
	menu
}

## INICIO APLICACION
clear
soyroot
menu
