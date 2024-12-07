while :
do
cd $HOME/server/
gdb -x=$HOME/server/scripts/Restarter/World/GDB/gdbcommands -batch $HOME/server/bin/worldserver > $HOME/server/logs/Server.log
mv $HOME/server/logs/Server.log $HOME/logs/crashes/log$(date +\%Y-\%m-\%d-\%H-\%M-\%S).log
done