#!/usr/bin/env bash

# Update all packages
echo "Updating the Virtual Machine"
echo "(It can take some time)..."
sudo apt-get -y update &> /dev/null || echo "[Error] Failed to update..."
sudo apt-get -y dist-upgrade &> /dev/null || echo "[Error] Failed to upgrade..."

# Set up sharing the folder with the host OS
if [ ! -d "/home/vagrant/tmwAthena/" ]; then
  echo "Setting up folder sharing for content..."
  ln -fs /vagrant/ /home/vagrant/tmwAthena &> /dev/null
else
  echo "Folder sharing already set up. Skipping."
fi

# Set up tmwa and tmwa-server-data repositories and compile tmwa
if [ -d "/home/vagrant/tmwAthena/tmwa" ]; then
  echo "Checking for updates for the themanaworld/tmwa clone..."
  cd /home/vagrant/tmwAthena/tmwa
  git fetch --all &> /dev/null
  echo "Switching to branch stable to preserve local changes..."
  git checkout stable &> /dev/null || echo "[Error] Failed to switch branches."
  git pull &> /dev/null || echo "[Error] Failed to pull repo"
  echo "Rebuilding tmwa (please be patient, this can take some time)..."
  # Always rebuild as new anything can break code
  make clean &> /dev/null
  ./configure &> /dev/null || echo "[Error] Configure failed for tmwa."
  make &> /dev/null || echo "[Error] Building tmwa failed."
  sudo make install &> /dev/null || echo "[Error] Make install for tmwa failed."
else
  echo "Cloning themanaworld/tmwa..."
  cd /home/vagrant/tmwAthena
  git clone --recursive git://github.com/themanaworld/tmwa.git &> /dev/null || echo "[Error] Cloning tmwa failed."
  cd /home/vagrant/tmwAthena/tmwa
  echo "Building tmwa (please be patient, this can take some time)..."
  ./configure &> /dev/null || echo "[Error] Configure failed for tmwa."
  make &> /dev/null || echo "[Error] Building tmwa failed."
  sudo make install &> /dev/null || echo "[Error] Make install for tmwa failed."
  git config --global url.git@github.com:.pushInsteadOf git://github.com
fi
if [ -d "/home/vagrant/tmwAthena/tmwa-server-data" ]; then
  echo "Checking for updates for the themanaworld/tmwa-server-data clone..."
  cd /home/vagrant/tmwAthena/tmwa-server-data
  git fetch --all &> /dev/null
  echo "Switching to branch master to preserve local changes..."
  git checkout master &> /dev/null || echo "[Error] Failed to switch branches."
  TMWASD_UPDT=$(git pull)
  if [ "$TMWASD_UPDT" == "Already up-to-date." ]; then
    echo "themanaworld/tmwa-server-data clone is already up to date."
  else
    echo "Updating magic..."
    cd /home/vagrant/tmwAthena/tmwa-server-data/world/map/conf
    echo "themanaworld/tmwa-server-data clone updated."
  fi
else
  echo "Cloning themanaworld/tmwa-server-data..."
  cd /home/vagrant/tmwAthena
  git clone --recursive git://github.com/themanaworld/tmwa-server-data.git &> /dev/null || echo "[Error] Cloning tmwa-server-data failed."
  cd tmwa-server-data
  echo "Setting up update hooks..."
  ln -s ../../git/hooks/post-merge .git/hooks/ &> /dev/null
  ln -s ../../../../git/hooks/post-merge .git/modules/client-data/hooks/ &> /dev/null
  echo "Creating the configuration files..."
  make conf &> /dev/null || echo "[Error] make conf failed.."
  # Checkout master branches inside client-data
  cd client-data &> /dev/null
  git checkout master &> /dev/null
  cd music &> /dev/null
  git checkout master &> /dev/null
fi

# Check for admin account and create it if it doesn't exist
cd /home/vagrant/tmwAthena/tmwa-server-data/login/save
CHK_ACC=$(cat account.txt | grep admin)
if [ "$CHK_ACC" == "" ]; then
  echo "GM account can't be found, creating..."
  cd /home/vagrant/tmwAthena/tmwa-server-data/login
  tmwa-admin <<END
add admin M vagrant
gm admin 99
exit
exit
END
else
  echo "GM account is already set up."
fi

# Run the tmwa server
cd /home/vagrant/tmwAthena/tmwa-server-data/
echo "Starting the server..."
./run-all &
sleep 15

# Output info about the server
echo " "
echo "##############################################################################"
echo "#                                                                            #"
echo "#   Server is now running.                                                   #"
echo "#   You can reach it by adding a new server to your client.                  #"
echo "#                                                                            #"
echo "#   Name: Local Server                                                       #"
echo "#   Address: localhost                                                       #"
echo "#   Port: 6901                                                               #"
echo "#   Server type: TmwAthena                                                   #"
echo "#                                                                            #"
echo "#   A GM level 99 account has been created with the following credentials.   #"
echo "#                                                                            #"
echo "#   Username: admin                                                          #"
echo "#   Password: vagrant                                                        #"
echo "#   Have fun!                                                                #"
echo "#                                                                            #"
echo "##############################################################################"
