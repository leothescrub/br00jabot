#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
Servidor DNS en Debian Wheezy

1. Instalamos los paquetes necesarios para el servidor DNS

# 1 root@TuX:/home/h3ns3r# aptitude install bind9 bind9-doc dnsutils

2. Toda la configuración se encuentra en /etc/bind/

3. La configuración que se genera por defecto es funcional totalmente, sin embargo;  personalizaremos la instalacion en dos aspectos que son: a cuáles servidores consultará nuestro servidor para pedir ayuda en la resolución de nombres, si no es posible hacer esto localmente (forwarders) y vamos a fortalecer varios aspectos de seguridad.
options {
        directory "/var/cache/bind";
 
        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113
 
        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.
 
        forwarders {
             // Servidores DNS de OpenDNS
             208.67.222.222;
             208.67.220.220;
             // ADSL router
             192.168.1.1;
        };
 
        // Opciones de Seguridad
        listen-on port 53 { 127.0.0.1; 192.168.1.5; }; 
        allow-query { 127.0.0.1; 192.168.1.0/24; };
        allow-recursion { 127.0.0.1; 192.168.1.0/24; };
        allow-transfer { none; };
 
        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation auto;
 
        auth-nxdomain no;    # conform to RFC1035
        // listen-on-v6 { any; };
};

6. Verificamos si el archivo fue correctamente editado

1 root@TuX:/etc/bind# named-checkconf 

7. Actualizar el Archivo /etc/resolv.conf  para que la resolución de nombres se realice localmente.

/etc/resolv.conf 
nameserver 127.0.0.1

8. Verificar  que en el archivo /etc/nsswitch.conf la resolución de nombres pase también por el servicio DNS
/etc/nsswitch.conf
# [...]
hosts:	files dns
# [...]
9. Reiniciamos el servidor DNS

root@TuX:/etc/bind# named-checkconf /etc/init.d/bind9 restart

Servidor DHCP en Debian Wheezy
1. Instalamos los paquetes necesarios para su funcionamiento
root@TuX:/home/h3ns3r# aptitude install isc-dhcp-server

2. Configuración
El servicio DHCP sólo debe estar disponible para la red interna. Por eso, debe aceptar conexiones por la interfaz interna (eth0, en este caso). Esto puede indicarse en el archivo de configuración/etc/default/isc-dhcp-server:
/etc/default/isc-dhcp-server
# Defaults for dhcp initscript
# sourced by /etc/init.d/dhcp
# installed at /etc/default/isc-dhcp-server by the maintainer scripts

#
# This is a POSIX shell fragment
#
5. En este archivo se indica el nombre del dominio (option domain-name “uptms.edu.ve”;), las direcciones de los servidores DNS (option domain-name-servers 192.168.15.1).
/etc/dhcp/dhcpd.conf
#
# Sample configuration file for ISC dhcpd for Debian
#
#

# The ddns-updates-style parameter controls whether or not the server will
# attempt to do a DNS update when a lease is confirmed. We default to the
# behavior of the version 2 packages ('none', since DHCP v2 didn't
# have support for DDNS.)
ddns-update-style none;

# option definitions common to all supported networks...
option domain-name "uptms.edu.ve";
option domain-name-servers 192.168.15.1;

default-lease-time 600;
max-lease-time 7200;

# If this DHCP server is the official DHCP server for the local
# network, the authoritative directive should be uncommented.
authoritative;

# Use this to send dhcp log messages to a different log file (you also
# have to hack syslog.conf to complete the redirection).
log-facility local7;

## SubNet home.lan
subnet 192.168.15.0 netmask 255.255.255.0 {
  range 192.168.15.32 192.168.15.63;
  option routers 192.168.15.1;
  option broadcast-address 192.168.15.255;
}
# [...]
7. Reiniciamos el Servicio para cargar la configuración
root@TuX:/home/h3ns3r# /etc/init.d/isc-dhcp-server restart

Servidor Squid en Debian Wheezy
1.  Instalación
root@TuX:/home/h3ns3r# aptitude install squid

2. La configuración de squid3 se almacena en el archivo /etc/squid3/squid.conf.


3.  squid3 acepta, por defecto, conexiones en el puerto 3128.  Sin embargo, esto puede modificarse colocando otro puerto por ejemplo el conocido 8080.
etc/squid3/squid.conf
#[...]

# Squid normally listens to port 3128
http_port 3128

#[...]

4. Por seguridad, squid3 sólo responderá a pedidos de la red local o en el propio servidor. Esta restricción es conseguida definiendo una lista de control de acceso oACL (Access Control List) (acl uptms.edu.ve src 192.168.15.0/24) y autorizando el acceso sólo a los sistemas incluidos en esa lista (http_access allow uptms.edu.ve):
etc/squid3/squid.conf
# [...]

#  TAG: acl
#       Defining an Access List

# [...]

#Default:
# acl all src all
#
#
# Recommended minimum configuration:
#
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
#acl localnet src 10.0.0.0/8    # RFC1918 possible internal network
#acl localnet src 172.16.0.0/12 # RFC1918 possible internal network
#acl localnet src 192.168.0.0/16        # RFC1918 possible internal network
#acl localnet src fc00::/7       # RFC 4193 local private network range
#acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl uptms.edu.ve src 192.168.15.1/24

# [...]

5.  Definición de permisos de acceso a la sección http_access:
/etc/squid3/squid.conf
# [...]

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
#http_access allow localnet
http_access allow localhost

http_access allow uptms.edu.ve

# And finally deny all other access to this proxy
http_access deny all

# [...]

6. Modificamos el  tamaño total de la cache de squid3 a un valor adecuado ejemplo 2048Mb
etc/squid3/squid.conf
# [...]

# Uncomment and adjust the following to add a disk cache directory.
#cache_dir ufs /var/spool/squid3 100 16 256
cache_dir ufs /var/spool/squid3 2048 16 256

# [...]

7.  Tambien podemos definir la identificación de nuestro servidor proxy
/etc/squid3/squid.conf
# [...]

#  TAG: visible_hostname
#       If you want to present a special hostname in error messages, etc,
#       define this.  Otherwise, the return value of gethostname()
#       will be used. If you have multiple caches in a cluster and
#       get errors about IP-forwarding you must set them to have individual
#       names with this setting.
#Default:
# visible_hostname localhost
visible_hostname proxy.uptms.edu.ve

# [...]

8. De manera opcional, también se puede configurar el límite máximo de los objetos que se guarden en el cache, al definir el parámetro maximum_object_size con un valor en Kbytes:
/etc/squid3/squid.conf
# [...]

#  TAG: maximum_object_size     (bytes)
#       Objects larger than this size will NOT be saved on disk.  The
#       value is specified in kilobytes, and the default is 4MB.  If
#       you wish to get a high BYTES hit ratio, you should probably
#       increase this (one 32 MB object hit counts for 3200 10KB
#       hits).  If you wish to increase speed more than your want to
#       save bandwidth you should leave this low.
#
#       NOTE: if using the LFUDA replacement policy you should increase
#       this value to maximize the byte hit rate improvement of LFUDA!
#       See replacement_policy below for a discussion of this policy.
#Default:
# maximum_object_size 4096 KB
maximum_object_size 20480 KB

# [...]

9. Reiniciamos el servicio squid
root@TuX:/home/h3ns3r# /etc/init.d/squid restart

Servidor Samba en Debian Wheezy

1. Instalamos las aplicaciones necesarias
root@TuX:/home/h3ns3r# aptitude install samba

4. La configuración por defecto trae muchas lineas de comentarios y ejemplos que no son necesarias tenerlas. Eliminaremos estas lineas automáticamente utilizando el comando testparm, ya que se cuenta con un archivo respaldo.
root@TuX:/home/h3ns3r# testparm -s smb.conf.respaldo > smb.conf

5.  visualizamos que el archivo smb.conf tiene menos tamaño que el respaldo
root@TuX:/etc/samba# ls -l
total 20
-rw-r--r-- 1 root root     0 abr 30 14:42 dhcp.conf
-rw-r--r-- 1 root root     8 ago 15  2013 gdbcommands
-rw-r--r-- 1 root root   805 jul 13 17:56 smb.conf
-rw-r--r-- 1 root root 12173 jul 13 17:55 smb.conf.respaldo

6. Editamos el archivo smb.conf y agregamos las siguientes lineas que están resaltadas sin los comentarios.


[global]
        workgroup = UPTMS # Nombre del grupo de la red
        netbios name = MISERVIDOR #nombre del servidor
        security = user #  Como los clientes Responden a Samba
        server string = %h server
        map to guest = Bad User
        obey pam restrictions = Yes
7. Nos salimos de root y creamos el directorio que queremos compartir con mkdir samba

8. Volvemos a logearnos como root y creamos el usuario para samba.
root@TuX:/etc/samba# smbpasswd -a estudiante
New SMB password:
Retype new SMB password:
Added user estudiante

9. Editamos el archivo smb.conf para agregar la información de la carpeta que hemos creado para compartir
[samba]
        comment = Carpeta de prueba para servidor samba
        path = /home/estudiante/samba
        read only = yes
        valid users = @users
        read list = @users

10. Por conveniencia, adicionamos a todos los usuarios creados al grupo users. Muy conveniente para carpetas públicas con permisos de sólo lectura o de lectura/escritura.
root@TuX:/home/h3ns3r# adduser estudiante users

11. Reiniciamos el Servicio
root@TuX:/home/h3ns3r# /etc/init.d/samba restart
