#!/bin/bash  

#export VIPs="66.0.194.148 67.220.118.155 67.220.118.151 www.apartmentguide.com"
#export VIPs="66.0.194.148 67.220.118.151 172.22.16.27:6081 172.16.122.101:6081 www.apartmentguide.com"
#export VIPs="172.22.16.11:6081 172.16.122.101:6081 67.220.118.155 www.apartmentguide.com"
#export VIPs="www.apartmentguide.com"
#export URLPATH='apartments/Kentucky/Louisville/Woods-of-Bridgewood/34751/'
#export URLPATH='apartments/Texas/Dallas/'
#export URLPATH='apartments/Kentucky/Louisville/'

export VIPs="shaggy.rain.hpcinteractive.com"
export URLPATHs='/cgi-bin/imagemgr/content?uuid=BD5AAF17-1C3D-4424-ADF6-A6D445444784 /cgi-bin/imagemgr/fcontent?uuid=BD5AAF17-1C3D-4424-ADF6-A6D445444784'

n=${1:-5}

i=0
while [ $i -lt $n ]
do
#	for VIP in $VIPs
	for URLPATH in $URLPATHs
	do
		curl -s -o /dev/null -H "Host: image.apartmentguide.com" \
			-w "iteration: $i  rc:%{http_code} time:%{time_total} 1st Byte:%{time_starttransfer} size:%{size_download} URI:$URLPATH\n" \
			"http://$VIPs/$URLPATH" &
	done
	wait
	((i++))
	echo
done
