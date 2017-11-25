
if [ "$1" == "system" ]; then
	echo "Installing as SYSTEM service!"
else
	echo "Installing as USER service!"
fi

echo ""
echo "Installing alsa-tools, needed to toggle pins to enable subwoofer..."
sudo apt-get install -y alsa-tools
username="$(/usr/bin/getent passwd 1000 | /usr/bin/cut -d: -f1)"

echo ""
echo "Clearing old /etc/sudoers.d/subwoofer file (if existing)..."
sudo rm /etc/sudoers.d/subwoofer

echo ""
echo "Allowing '/usr/bin/hda-verb' to be executed without sudo..."
echo $username' ALL=NOPASSWD: /usr/bin/hda-verb' | sudo EDITOR='tee' visudo -f /etc/sudoers.d/subwoofer
echo 'guest ALL=NOPASSWD: /usr/bin/hda-verb' | sudo EDITOR='tee -a' visudo -f /etc/sudoers.d/subwoofer

echo ""
echo "Clearing old subwoofer script (if existing)..."
sudo rm /opt/subwoofer.py

echo ""
echo "Installing fresh subwoofer script to '/opt'..."
sudo cp ./subwoofer.py /opt/subwoofer.py
sudo chmod +x /opt/subwoofer.py

echo ""
echo "Clearing old subwoofer service (if existing)..."
sudo rm /etc/systemd/system/subwoofer.service
sudo rm /etc/systemd/user/subwoofer.service

echo ""
echo "Installing fresh subwoofer service to '/etc/systemd/system'..."
systemctl --user stop subwoofer &> /dev/null
systemctl --user disable subwoofer &> /dev/null
sudo systemctl stop subwoofer &> /dev/null
sudo systemctl disable subwoofer &> /dev/null
if [ "$1" == "system" ]; then
	sudo cp ./subwoofer.service /etc/systemd/system/subwoofer.service
else
	sudo cp ./subwoofer.service /etc/systemd/user/subwoofer.service
fi

echo ""
echo "Clearing old suspend script '/etc/pm/sleep.d/subwoofer.sh'..."
sudo rm /etc/pm/sleep.d/subwoofer.sh

echo ""
echo "Copying fresh 'subwoofer.sh' to '/etc/pm/sleep.d/' to stop subwoofer on suspends..."
sudo cp ./subwoofer.sh /etc/pm/sleep.d/subwoofer.sh
sudo chmod +x /etc/pm/sleep.d/subwoofer.sh

echo ""
echo "Enabling (not starting!) service..."
# Both need reload in case you changed from user to system service, or the other way around
sudo systemctl daemon-reload
systemctl --user daemon-reload

if [ "$1" == "system" ]; then
	sudo systemctl enable subwoofer
else
	systemctl --user enable subwoofer
fi

echo ""
echo "Starting service..."
if [ "$1" == "system" ]; then
	sudo systemctl stop subwoofer.service
	sudo systemctl start subwoofer.service
else
	systemctl --user stop subwoofer.service
	systemctl --user start subwoofer.service
fi

echo ""
echo "Done! Change volume to hear it."

echo ""
echo ""

if [ "$1" == "system" ]; then
	echo "Please run 'sudo systemctl status subwoofer'. Is the service reported as active?"
	echo "Please check the subwoofer by running some sound, changing volume a bit and putting your ear on it. Does it work?"
	echo "Please take note of the 'Main PID' from running 'sudo systemctl status subwoofer' and check with 'top -p [PID]'"
	echo " if the script consumes more than 0% CPU when no volume is changed (regardless if sound is played or not)."
	echo ""
	echo "If it does consume more than 0% CPU or there are any other errors, please try restarting and recheck the same thing and"
	echo " if it still doesn't work properly, try running 'install.sh user' or going on"
	echo " https://github.com/dragosprju/y50-subwoofer-linux-enabler to report your problem and findings."
else
	echo "Please run 'systemctl --user status subwoofer'. Is the service reported as active?"
	echo "Please check the subwoofer by running some sound, changing volume a bit and putting your ear on it. Does it work?"
	echo "Please take note of the 'Main PID' from running 'systemctl --user status subwoofer' and check with 'top -p [PID]'"
	echo " if the script consumes more than 0% CPU when no volume is changed (regardless if sound is played or not)."
	echo ""
	echo "If it does consume more than 0% CPU or there are any other errors, please try restarting and recheck the same thing and"
	echo " if it still doesn't work properly, try running 'install.sh system' or going on"
	echo " https://github.com/dragosprju/y50-subwoofer-linux-enabler to report your problem and findings."
fi
