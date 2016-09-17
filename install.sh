sudo apt-get install alsa-tools
username="$(/usr/bin/getent passwd 1000 | /usr/bin/cut -d: -f1)"
sudo echo $username' ALL=NOPASSWD: /usr/bin/hda-verb' >> /etc/sudoers
sudo echo 'guest ALL=NOPASSWD: /usr/bin/hda-verb' >> /etc/sudoers
sudo cp ./subwoofer.py /opt/subwoofer.py
sudo chmod +x /opt/subwoofer.py
sudo cp ./subwoofer.service /etc/systemd/user/subwoofer.service
systemctl --user daemon-reload
systemctl --user enable subwoofer
echo "Please restart the computer to start the 'subwoofer' service."
