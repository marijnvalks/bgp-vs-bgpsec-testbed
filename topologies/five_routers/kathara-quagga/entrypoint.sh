#!/bin/bash
# Start zebra and bgpd in background
/usr/sbin/zebra -d -f /etc/quagga.conf
/usr/sbin/bgpd -d -f /etc/bgpd.conf

# Keep container alive
tail -f /dev/null
