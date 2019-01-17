#########################################################################
# File Name: switchIPForBWG.sh
# Author: liukun
# mail: 827423346@qq.com
# Created Time: Thu 17 Jan 2019 01:57:32 PM CST
#########################################################################
#!/bin/bash


veid=1205610
apiKey=private_cIPULsHJJNDZpiewIWo9FWO4

DATE=$(date +"%Y-%m-%d %H:%M.%S")
function log_sucess()
{
  echo -e "$DATE  [success]  $1" >> /root/switchIPForBWG.log
}

function log_fail()
{
  echo -e "$DATE  [error]  $1" >> /root/switchIPForBWG.log
}

function log_normal()
{
  echo -e "$DATE  [info]  $1" >> /root/switchIPForBWG.log
}

function send_email() 
{
	echo $1 | mail -s "搬瓦工IP切换 $DATE" 827423346@qq.com
}

serviceInfo=$(curl -s "https://api.64clouds.com/v1/getServiceInfo?&veid=$veid&api_key=$apiKey")
echo $serviceInfo | grep '"error":0' >/dev/null || {
	log_fail "get service infomation failed"
	send_email "服务器信息获取失败"
	exit 1
} && {
	log_sucess "get service infomation success"
}

serviceIP=$(echo $serviceInfo | cut -d":" -f4 | cut -d"," -f1 |sed 's#"##g') && {
	log_normal "serviceIP = $serviceIP" 
} || {
	send_email "服务器原IP获取失败"
}

serviceLoc=$(curl -s "https://api.64clouds.com/v1/migrate/getLocations?&veid=$veid&api_key=$apiKey")
echo $serviceLoc | grep '"error":0' >/dev/null || {
	log_fail "get service location failed"
	send_email "服务器地址列表获取失败"
	exit 1
} && {
	log_sucess "get service location success"
}

location=$(echo $serviceLoc | sed -r 's#^\{\"error.*locations\"\:\[##g;s#\"\]\,\"descriptions.*##g;s#"##g' ) && {
	log_normal "location = $location"
} || {
	log_fail "location process fail"
	send_email "服务器地址列表处理失败"
	exit 1
}

#awk处理locaitin后，将值存放到数组变量中。
eval $(echo $location | awk  '{split ($0,locArray,",") ; for(i in locArray)print "array["i"]="locArray[i]}')

# 开始切换区域
function switchLocal() 
{
	# 生成各位随机数
	random=$(echo $RANDOM | cut -c 1)
	newLocation=${array[$random]}
	log_normal "newLocation= $newLocation"	

	# 切换区域
	result=$(curl -s "https://api.64clouds.com/v1/migrate/start?location=${newLocation}&veid=${veid}&api_key=${apiKey}")
	echo $result | grep "Please try again in 10-15 minutes." >/dev/null && {
		log_fail "Migration backend is currently not available for this VPS. Please try again in 10-15 minutes."
		send_email "搬瓦工服务器依然处于锁定状态，IP地址切换不成功"
		exit 1
	}
	echo $result | grep "Unable to migrate into same location" >/dev/null && {
		log_fail "Unable to migrate into same location,switchLocal again"
		switchLocal
	}
}

switchLocal






