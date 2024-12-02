while :
do
cd $HOME/server/
gdb -x=$HOME/server/scripts/Restarter/World/GDB/gdbcommands -batch $HOME/server/bin/worldserver > $HOME/public/logs/Server.log
mv $HOME/public/logs/Server.log $HOME/public/logs/crashes/log$(date +\%Y-\%m-\%d-\%H-\%M-\%S).log
done