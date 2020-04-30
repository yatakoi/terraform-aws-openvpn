/* NAT/VPN server */
resource "aws_instance" "nat" {
  ami = lookup(var.amis, var.region)
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  security_groups = [aws_security_group.default.id, aws_security_group.nat.id]
  key_name = aws_key_pair.deployer.key_name
  source_dest_check = false

  connection {
    user = "ubuntu"
    private_key = file("ssh/insecure-deployer")
	host     = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo iptables -t nat -A POSTROUTING -j MASQUERADE",
      "echo 1 | sudo tee /proc/sys/net/ipv4/conf/all/forwarding > /dev/null",
      /* Install docker */
      "sudo apt-get remove docker docker-engine docker.io containerd runc",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
      "sudo apt-get -y install docker-ce docker-ce-cli containerd.io",
      "sudo usermod -aG docker ubuntu",
      /* Создание переменной OVPN_DATA */
      "OVPN_DATA=\"ovpn-data\"",
      "CLIENTNAME=\"yatakoi\"",
      "sudo docker volume create --name $OVPN_DATA",
      /* Generate OpenVPN server config */
      "sudo docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://aws_instance.nat.public_ip",
      /* Generate the EasyRSA PKI certificate authority */
      "sudo docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki",
      "sudo docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp ----cap-add=NET_ADMIN kylemanna/openvpn",
      "sudo docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENTNAME nopass",
      "sudo docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient $CLIENTNAME"
    ]
  }
}
