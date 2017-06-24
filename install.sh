sudo apt-get install -y alsa-tools
username="$(/usr/bin/getent passwd 1000 | /usr/bin/cut -d: -f1)"
echo $username' ALL=NOPASSWD: /usr/bin/hda-verb' | sudo EDITOR='tee' visudo -f /etc/sudoers.d/subwoofer
echo 'guest ALL=NOPASSWD: /usr/bin/hda-verb' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/subwoofer
sudo cp ./subwoofer.py /opt/subwoofer.py
sudo chmod +x /opt/subwoofer.py
sudo cp ./subwoofer.service /etc/systemd/system/subwoofer.service
systemctl daemon-reload
systemctl enable subwoofer.service
echo "Please restart the computer to start the 'subwoofer' service."
