#!/bin/bash
#cleaning and updating Kali

apt auto-remove -y && apt auto-clean -y
apt update -y && apt upgrade -y

echo ''
echo ''
echo ''
echo '----------------------'
echo 'all done :)'
