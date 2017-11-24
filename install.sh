echo ""
echo ""
echo "Installing alsa-tools, needed to toggle pins to enable subwoofer..."
sudo apt-get install -y alsa-tools
username="$(/usr/bin/getent passwd 1000 | /usr/bin/cut -d: -f1)"

echo ""
echo ""
echo "Clearing old /etc/sudoers.d/subwoofer file (if existing)..."
sudo rm /etc/sudoers.d/subwoofer

echo ""
echo ""
echo "Allowing '/usr/bin/hda-verb' to be executed without sudo..."
echo $username' ALL=NOPASSWD: /usr/bin/hda-verb' | sudo EDITOR='tee' visudo -f /etc/sudoers.d/subwoofer
echo 'guest ALL=NOPASSWD: /usr/bin/hda-verb' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/subwoofer

echo ""
echo ""
echo "Clearing old subwoofer script (if existing)..."
sudo rm /opt/subwoofer.py

echo ""
echo ""
echo "Installing fresh subwoofer script to '/opt'..."
sudo cp ./subwoofer.py /opt/subwoofer.py
sudo chmod +x /opt/subwoofer.py

echo ""
echo ""
echo "Clearing old subwoofer service (if existing)..."
sudo rm /etc/systemd/system/subwoofer.service

echo ""
echo ""
echo "Installing fresh subwoofer service to '/etc/systemd/system'..."
sudo cp ./subwoofer.service /etc/systemd/system/subwoofer.service

echo ""
echo ""
echo "Clearing old suspend script '/etc/pm/sleep.d/subwoofer.sh'..."
sudo rm /etc/pm/sleep.d/subwoofer.sh

echo ""
echo ""
echo "Copying fresh 'subwoofer.sh' to '/etc/pm/sleep.d/' to stop subwoofer on suspends..."
sudo cp ./subwoofer.sh /etc/pm/sleep.d/subwoofer.sh
sudo chmod +x /etc/pm/sleep.d/subwoofer.sh

echo ""
echo ""
echo "Enabling (not starting!) service..."
sudo systemctl daemon-reload
sudo systemctl enable subwoofer.service

echo ""
echo ""
echo "Starting service..."
sudo systemctl stop subwoofer.service
sudo systemctl start subwoofer.service

echo ""
echo ""
echo "Done! Change volume to hear it."
