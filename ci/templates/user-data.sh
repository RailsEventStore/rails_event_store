#!/bin/bash -x
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

${pre_install}

# Install AWS CLI
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  awscli \
  jq \
  curl \
  wget \
  git \
  uidmap \
  build-essential \
  unzip \
  libsqlite3-dev \
  libpq-dev \
  libmysqlclient-dev

USER_NAME=runners
useradd -m -s /bin/bash $USER_NAME
USER_ID=$(id -ru $USER_NAME)

# install and configure cloudwatch logging agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${ssm_key_cloudwatch_agent_config}

# configure systemd for running service in users accounts
cat >/etc/systemd/user@UID.service <<-EOF

[Unit]
Description=User Manager for UID %i
After=user-runtime-dir@%i.service
Wants=user-runtime-dir@%i.service

[Service]
LimitNOFILE=infinity
LimitNPROC=infinity
User=%i
PAMName=systemd-user
Type=notify

[Install]
WantedBy=default.target

EOF

echo export XDG_RUNTIME_DIR=/run/user/$USER_ID >>/home/$USER_NAME/.profile

systemctl daemon-reload
systemctl enable user@UID.service
systemctl start user@UID.service

curl -fsSL https://get.docker.com/rootless >>/opt/rootless.sh && chmod 755 /opt/rootless.sh
su -l $USER_NAME -c /opt/rootless.sh
echo export DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>/home/$USER_NAME/.profile
echo export PATH=/home/$USER_NAME/bin:$PATH >>/home/$USER_NAME/.profile

# Run docker service by default
loginctl enable-linger $USER_NAME
su -l $USER_NAME -c "systemctl --user enable docker"

${install_config_runner}

# config runner for rootless docker
cd /home/$USER_NAME/actions-runner/
echo DOCKER_HOST=unix:///run/user/$USER_ID/docker.sock >>.env
echo PATH=/home/$USER_NAME/bin:$PATH >>.env
echo ImageOS=ubuntu20 >> .env

mkdir /opt/hostedtoolcache
chmod -R 777 /opt/hostedtoolcache

# Install Chrome.
sudo curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
sudo echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
sudo apt-get -y update
sudo apt-get -y install google-chrome-stable


# Chromedriver
export CHROME_DRIVER_VERSION=95.0.4638.69
wget -N https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/
unzip ~/chromedriver_linux64.zip -d ~/
rm ~/chromedriver_linux64.zip
mv -f ~/chromedriver /usr/local/bin/chromedriver
chown root:root /usr/local/bin/chromedriver
chmod 0755 /usr/local/bin/chromedriver

${post_install}

./svc.sh start
