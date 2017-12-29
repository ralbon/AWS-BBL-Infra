#! /bin/bash

cd /home/ec2-user
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2SuiNyMBAZai4dYmT3Of11u6yh6hyqwi4AbTE0nQpfIHuuPSLmIJywcrjhJWBy7Xnkef5Ij3Z1PDKnQ/wHr/HChcaxgcoCdjVW3MNXYpkAkWsB7m2xdqsbTrGcyRWHNUXOJ51AzzytjcoaE7W4e8P3p+bxdlvgU3YKVOjOSvJ67g9BnFP+00vEvPleuLJ/8DtXhImEuunxO8qU9dwyyzvJPZPPrH2bdF/VOQ4txmct2GwG/kA4SyVpvMB2JUHkCBPo/JeV3Tr5eeTPJrtTP7Pbf3Kiz7y1DlD97mAMopi3vtnD12N0/EVGMnBnR4iqct6MWvUudSUCoifCOs526CB RAL@MBP-de-RAL-Octo.paris.octo" >> .ssh/authorized_keys

sudo yum -y install git
sudo yum -y install docker
sudo pip install docker-compose
sudo service docker start
git clone https://github.com/CYYG/catvsdog-vote.git
cd catvsdog-vote/
sudo REDIS_HOST=${REDIS_HOST}  `which docker-compose` up
