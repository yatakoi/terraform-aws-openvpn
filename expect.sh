#!/usr/bin/env bash

DATE=$(date +%Y%m%d-%H%M)
USERNAME=${1}
CAPASS=${2}
USERPASS=${3}

expect <<END
	spawn docker exec -it openvpn easyrsa build-client-full ${USERNAME} 
	expect "Enter PEM pass phrase:"
	send ${USERPASS}\r
	expect "Verifying - Enter PEM pass phrase:"
	send ${USERPASS}\r
	expect "Enter pass phrase for /etc/openvpn/pki/private/ca.key:"
	send ${CAPASS}\r
	expect "Data Base Updated"	
END

SAVEPATH="/home/$USER"

# For some reason the username contain newline that must be removed
USERNAME=${USERNAME//$'\015'}

# Fetch ovpn file and move to local folder
sudo docker exec -it openvpn ovpn_getclient $USERNAME > "$SAVEPATH/$USERNAME-$DATE.ovpn"
