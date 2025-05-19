#!/bin/bash

echo "===== Server Performance Stats ====="
echo ""

# 1. Total CPU Usage (overall CPU usage percentage)
# Use mpstat if available, fallback to top parsing
if command -v mpstat &> /dev/null; then
    CPU_IDLE=$(mpstat 1 1 | awk '/Average/ {print 100 - $NF}')
    printf "Total CPU Usage: %.2f%%\n" "$CPU_IDLE"
else
    CPU_IDLE=$(top -bn2 | grep "Cpu(s)" | tail -n1 | awk -F'id,' -v prefix=$prefix '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); print 100 - v }')
    printf "Total CPU Usage: %.2f%%\n" "$CPU_IDLE"
fi

# 2. Total Memory Usage (Free vs Used including percentage)
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_FREE=$(free -m | awk '/Mem:/ {print $4}')
MEM_PERCENT=$(( MEM_USED * 100 / MEM_TOTAL ))
echo "Memory Usage: $MEM_USED MB used / $MEM_TOTAL MB total (${MEM_PERCENT}%)"

# 3. Total Disk Usage (Free vs Used including percentage) on root '/'
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
echo "Disk Usage (root): $DISK_USED used / $DISK_TOTAL total (Available: $DISK_AVAIL) - Usage: $DISK_PERCENT"

# 4. Top 5 processes by CPU usage
echo ""
echo "Top 5 Processes by CPU usage:"
ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6

# 5. Top 5 processes by Memory usage
echo ""
echo "Top 5 Processes by Memory usage:"
ps -eo pid,comm,%mem --sort=-%mem | head -n 6

# Stretch goals (optional):

# OS Version
echo ""
echo "OS Version:"
cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"'

# Uptime
echo "Uptime:"
uptime -p

# Load average
echo "Load Average:"
uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //'

# Logged in users
echo "Logged in Users:"
who | wc -l

# Failed login attempts (last 5 lines)
echo "Failed login attempts (last 5):"
sudo journalctl _SYSTEMD_UNIT=sshd.service --since "1 day ago" | grep "Failed password" | tail -n 5

echo ""
echo "===== End of Stats ====="
