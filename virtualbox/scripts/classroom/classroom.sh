#!/bin/bash
ca_dir=/root/ca
hostnamectl set-hostname classroom
echo "vagrant:vagrant" | chpasswd
echo "root:centos" | chpasswd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
sed -i.old /mirrorlist=.*repo=os/s/^/#/ /etc/yum.repos.d/CentOS-Base.repo
sed -i /mirrorlist=.*repo=updates/s/^/#/ /etc/yum.repos.d/CentOS-Base.repo
sed -i /mirrorlist=.*repo=extras/aenabled=0 /etc/yum.repos.d/CentOS-Base.repo
sed -i '/#baseurl=.*\/os/s/^#//' /etc/yum.repos.d/CentOS-Base.repo
sed -i '/#baseurl=.*\/updates/s/^#//' /etc/yum.repos.d/CentOS-Base.repo
sed -i /^baseurl=/s/mirror.centos.org/172.16.0.143/ /etc/yum.repos.d/CentOS-Base.repo
#yum -y update #adds up the build time uncomment if necessary
yum -y install bind-utils net-tools wget vim
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
yum -y install haveged
systemctl enable haveged
systemctl restart haveged
sed -i.old s/enabled=1/enabled=0/g /etc/yum.repos.d/epel.repo
yum -y install ntp
sed -i.old "17arestrict 192.168.33.0 mask 255.255.255.0 nomodify notrap" /etc/ntp.conf
systemctl enable ntpd
systemctl restart ntpd
yum -y install bind
sed -i.old 11s/127.0.0.1/any/g /etc/named.conf
sed -i 17s/localhost/any/g /etc/named.conf
sed -i "s/dnssec-validation yes/dnssec-validation no/g" /etc/named.conf
sed -i '29a\\tforward only;\n\tforwarders { 10.0.2.3; };' /etc/named.conf
sed -i '50azone "example.com" {\ntype master;\nfile "example.com.zone";\nallow-update { none; };\n};\n\nzone "33.168.192.in-addr.arpa" {\ntype master;\nfile "example.com.revzone";\nallow-update { none; };\n};' /etc/named.conf
cat > /var/named/example.com.zone << EOF
\$TTL 86400
@ IN SOA classroom.example.com. root.example.com. (
2014080601 ; Serial
 1d ; refresh
 2h ; retry
 4w ; expire
 1h ) ; min cache
 IN NS classroom.example.com.

classroom     IN A 192.168.33.254
server1       IN A 192.168.33.11
desktop1      IN A 192.168.33.10
EOF
cat > /var/named/example.com.revzone << EOF
\$TTL 86400
@ IN SOA classroom.example.com. root.example.com. (
 2014080601 ; Serial
 1d ; refresh
 2h ; retry
 4w ; expire
 1h ) ; min cache
 IN NS classroom.example.com.

254   IN PTR classroom.example.com.     
11    IN PTR server1.example.com.
10    IN PTR desktop1.example.com.
EOF
systemctl enable named
systemctl restart named
echo "domain example.com" > /etc/resolv.conf
yum -y install httpd
#ln -s /repos/centos /var/www/html
mkdir -p /var/www/html/keytab
mkdir -p /var/www/html/pki/tls/private /var/www/html/pki/tls/certs /var/www/html/scripts
sed -i s/^/#/g /etc/httpd/conf.d/welcome.conf
systemctl enable httpd
systemctl restart httpd
#yum -y install policycoreutils-python
#mv /etc/yum.repos.d/CentOS-Base.repo.old /etc/yum.repos.d/CentOS-Base.repo
#curl http://localhost/centos/ > /dev/null 2>&1
#curl http://localhost/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7 > /dev/null 2>&1
#curl http://localhost/centos/7/updates/x86_64/repodata/repomd.xml > /dev/null 2>&1
#curl http://localhost/centos/7/os/x86_64/CentOS_BuildTag > /dev/null 2>&1
#audit2allow -w -a > /tmp/blocked.log
#audit2allow -a > /tmp/rules.log
#grep vmblock_t /var/log/audit/audit.log | audit2allow -M httpd_vboxsf > /dev/null 2>&1
#semodule -i httpd_vboxsf.pp

#CA setup and setting up server and client certificates
mkdir -p ${ca_dir}/certs ${ca_dir}/crl ${ca_dir}/newcerts ${ca_dir}/private ${ca_dir}/csr
chmod 700 ${ca_dir}/private
touch ${ca_dir}/index.txt
echo 1000 > ${ca_dir}/serial
cp /usr/local/scripts/openssl.cnf ${ca_dir}
openssl req -new -config ${ca_dir}/openssl.cnf -newkey rsa:4096 -nodes -x509 -days 7300 -subj "/CN=example.com" -keyout ${ca_dir}/private/ca.key -out ${ca_dir}/certs/ca.crt
openssl genrsa -out ${ca_dir}/private/classroom.key 4096
openssl req -new -config ${ca_dir}/openssl.cnf -key ${ca_dir}/private/classroom.key -sha256 -out ${ca_dir}/csr/classroom.csr -subj "/CN=classroom.example.com"
openssl ca -batch -config ${ca_dir}/openssl.cnf -days 365 -notext -md sha256 -in ${ca_dir}/csr/classroom.csr -out ${ca_dir}/certs/classroom.crt
openssl genrsa -out ${ca_dir}/private/server1.key 4096
openssl req -new -config ${ca_dir}/openssl.cnf -key ${ca_dir}/private/server1.key -sha256 -out ${ca_dir}/csr/server1.csr -subj "/CN=server1.example.com"
openssl ca -batch -config ${ca_dir}/openssl.cnf -days 365 -notext -md sha256 -in ${ca_dir}/csr/server1.csr -out ${ca_dir}/certs/server1.crt
cp ${ca_dir}/certs/ca.crt /var/www/html/pki/example_ca.crt
cp ${ca_dir}/certs/server1.crt /var/www/html/pki/tls/certs/server1.crt
cp ${ca_dir}/private/server1.key /var/www/html/pki/tls/private/server1.key
cp ${ca_dir}/certs/classroom.crt /etc/openldap/certs
cp ${ca_dir}/certs/ca.crt /etc/openldap/certs
cp ${ca_dir}/private/classroom.key /etc/openldap/certs
cat > /var/www/html/scripts/epoch.py << EOF
# The application interface is a callable objects
import time

def application ( # It accepts two arguments:
    # environ points to a dictionary containing CGI like environment
    # variables which is populated by the server for each
    # received request from the client
    environ,
    # start_response is a callback function supplied by the server
    # which takes the HTTP status and headers as arguments
    start_response
):

    # Build the response body possibly
    # using the supplied environ dictionary
    response_body = 'Current UNIX Epoch Time is: %s' %time.time()  #% environ['REQUEST_METHOD']

    # HTTP response code and message
    status = '200 OK'

    # HTTP headers expected by the client
    # They must be wrapped as a list of tupled pairs:
    # [(Header name, Header value)].
    response_headers = [
        ('Content-Type', 'text/plain'),
        ('Content-Length', str(len(response_body)))
    ]

    # Send them to the server using the supplied function
    start_response(status, response_headers)

    # Return the response body. Notice it is wrapped
    # in a list although it could be any iterable.
    return [response_body]
EOF
yum -y install krb5-server krb5-workstation
sed -i.old s/^#//g /etc/krb5.conf
sed -i s/kerberos/classroom/g /etc/krb5.conf
kdb5_util create -s -P kerberosroot
systemctl enable krb5kdc kadmin
systemctl restart krb5kdc kadmin
kadmin.local -q "addprinc -pw kerberos root/admin"
kadmin.local -q "addprinc -randkey host/classroom.example.com"
kadmin.local -q "addprinc -randkey nfs/server1.example.com"
kadmin.local -q "ktadd nfs/server1.example.com"
mv /etc/krb5.keytab /var/www/html/keytab/server1.keytab
chmod 754 /var/www/html/keytab/server1.keytab
kadmin.local -q "addprinc -randkey nfs/desktop1.example.com"
kadmin.local -q "ktadd nfs/desktop1.example.com"
mv /etc/krb5.keytab /var/www/html/keytab/desktop1.keytab
chmod 754 /var/www/html/keytab/desktop1.keytab
kadmin.local -q "ktadd host/classroom.example.com"
echo kerberos | kinit root/admin@EXAMPLE.COM
yum install -y openldap openldap-clients openldap-servers migrationtools
#sed -i.old /olcSuffix/s/my-domain/example/ /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
#sed -i /olcRootDN/s/my-domain/example/ /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
#sed -i "/olcRootDN/aolcRootPW: $(slappasswd -ns test)" /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
#sed -i "/olcRootPW/aolcTLSCertificateFile: \/etc\/openldap\/certs\/cacert.pem" /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
#sed -i "/olcTLSCertificateFile/aolcTLSCertificateKeyFile: \/etc\/openldap\/certs\/cakey.pem" /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}hdb.ldif
#sed -i.old /dc=my-domain/s/my-domain/example/ /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{1\}monitor.ldif
#openssl req -new -x509 -nodes -out /etc/openldap/certs/cacert.pem -keyout /etc/openldap/certs/cakey.pem -days 365 -subj "/C=IN/O=Example/CN=classroom.example.com"
sed -i 's/TLS_CACERTDIR.*/TLS_CACERTDIR \/etc\/pki\/nssdb/g' /etc/openldap/ldap.conf
certutil -d /etc/pki/nssdb -A -n "rootca" -t CT -a -i ${ca_dir}/certs/ca.crt
chown -R ldap:ldap /etc/openldap/certs
chmod 600 /etc/openldap/certs/classroom.key
restorecon -R /etc/openldap/certs
restorecon -R /var/www/html
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap/
sed -i.old '/SLAPD_URLS/s/"$/ ldaps:\/\/\/"/' /etc/sysconfig/slapd
systemctl enable slapd
systemctl restart slapd
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/collective.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/corba.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/core.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/duaconf.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/dyngroup.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/java.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/misc.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/openldap.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/pmi.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/ppolicy.ldif
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=example,dc=com
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: "$(slappasswd -s test)"
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=example,dc=com" read by * none
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/classroom.crt
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/classroom.key
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/openldap/certs/classroom.key
EOF
sed -i.old "/$NAMINGCONTEXT{'group'}/s/ou=Group/ou=Groups/" /usr/share/migrationtools/migrate_common.ph
sed -i '/$DEFAULT_MAIL_DOMAIN/s/padl.com/example.com/' /usr/share/migrationtools/migrate_common.ph
sed -i '/$DEFAULT_BASE/s/padl/example/' /usr/share/migrationtools/migrate_common.ph
sed -i  '/$EXTENDED_SCHEMA/s/ = 0/ = 1/' /usr/share/migrationtools/migrate_common.ph
/usr/share/migrationtools/migrate_base.pl > base.ldif
ldapadd -x -w test -D "cn=Manager,dc=example,dc=com" -f base.ldif
#sed -i.old '/open(/s/\/etc\/shadow/shadow/' /usr/share/migrationtools/migrate_passwd.pl
mkdir -p /home/guests
useradd -d /home/guests/ldapuser1 ldapuser1
useradd -d /home/guests/ldapuser2 ldapuser2
useradd -d /home/guests/ldapuser3 ldapuser3
echo "ldapuser1:password" | chpasswd
echo "ldapuser2:password" | chpasswd
echo "ldapuser3:password" | chpasswd
kadmin.local -q "addprinc -pw kerberos ldapuser1"
kadmin.local -q "addprinc -pw kerberos ldapuser2"
kadmin.local -q "addprinc -pw kerberos ldapuser3"
getent passwd | tail -n 3 > users
getent shadow | tail -n 3 > shadow
getent group | tail -n 3 > groups
/usr/share/migrationtools/migrate_passwd.pl users > users.ldif
/usr/share/migrationtools/migrate_group.pl groups > groups.ldif
ldapadd -x -w test -D "cn=Manager,dc=example,dc=com" -f users.ldif
ldapadd -x -w test -D "cn=Manager,dc=example,dc=com" -f groups.ldif
systemctl restart slapd
echo "/home/guests 192.168.33.0/24(rw,sync)" > /etc/exports
systemctl enable nfs-server
systemctl restart nfs-server
echo "PEERDNS=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl enable firewalld
systemctl restart firewalld
firewall-cmd --permanent --add-service=ntp
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=kerberos
firewall-cmd --permanent --add-service=ldap
firewall-cmd --permanent --add-service=ldaps
firewall-cmd --reload
