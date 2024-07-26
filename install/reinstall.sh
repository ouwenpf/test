#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'

klustron_user=$(ls -l $0 | awk '{print $3}')
basedir="$HOME/softwares/cloudnative/cluster"
klustron_VERSION='1.3.2'
klustron_xpanel=($(sudo jq -r '.xpanel.nodes[] | "\(.ip):\(.port)"'  $basedir/klustron_config.json))
klustron_info=("$klustron_user" "$basedir" "$klustron_VERSION")


function  kunlun_user_env(){
if [[ ${klustron_info[0]} != "$USER" ]];then
  echo -e "$COL_START$RED 请在${klustron_user}用户下执行脚本$0$COL_END"
  exit
fi  


}

function kunlun_thirdparty(){

sudo -E su - ${klustron_info[0]} -c  "

if [[ -d ${klustron_info[1]} ]];then

	cd ${klustron_info[1]}/clustermgr/

	lan_net='http://192.168.0.104:14000'
	wal_net='http://zettatech.tpddns.cn:14000'

	if nc -z 192.168.0.104 14000; then

		urls=(
			\"\$lan_net/thirdparty/efk/elasticsearch-7.10.1.tar.gz\"
			\"\$lan_net/thirdparty/efk/filebeat-7.10.1-linux-x86_64.tar.gz\"
			\"\$lan_net/thirdparty/efk/kibana-7.10.1.tar.gz\"
			\"\$lan_net/thirdparty/hadoop-3.3.1.tar.gz\"
			\"\$lan_net/thirdparty/jdk-8u131-linux-x64.tar.gz\"
			\"\$lan_net/thirdparty/mysql-connector-python-2.1.3.tar.gz\"
			\"\$lan_net/thirdparty/prometheus.tgz\"
			\"\$lan_net/thirdparty/haproxy-2.5.0-bin.tar.gz\"
		)
	
	else

		urls=(
			\"\$wal_net/thirdparty/efk/elasticsearch-7.10.1.tar.gz\"
			\"\$wal_net/thirdparty/efk/filebeat-7.10.1-linux-x86_64.tar.gz\"
			\"\$wal_net/thirdparty/efk/kibana-7.10.1.tar.gz\"
			\"\$wal_net/thirdparty/hadoop-3.3.1.tar.gz\"
			\"\$wal_net/thirdparty/jdk-8u131-linux-x64.tar.gz\"
			\"\$wal_net/thirdparty/mysql-connector-python-2.1.3.tar.gz\"
			\"\$wal_net/thirdparty/prometheus.tgz\"
			\"\$wal_net/thirdparty/haproxy-2.5.0-bin.tar.gz\"
		)
	fi
	
else
  echo -e \"$COL_START$RED目录${klustron_info[1]}不存在$COL_END\"
  exit

fi

echo -e \"$COL_START${YELLOW}正在下载Klustron分布式数据库相关组件,请勿中断........$COL_END\" 

for url in \"\${urls[@]}\"; do
    filename=\$(basename \"\$url\")
    if  [[ ! -f \$filename ]];then
      if wget -q  --spider \"\$url\"; then
            wget  \"\$url\"   &>/dev/null
            if [[ \$? -ne 0 ]]; then
                echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
                let download_thirdparty++

            fi
        else
            echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
            let download_thirdparty++

      fi
    fi
done




<<!
for url in \"\${urls[@]}\"; do
    filename=\$(basename \"\$url\")
    if  [[ ! -f \$filename ]];then
      if wget -q  --spider \"\$url\"; then
            wget  \"\$url\"   &>/dev/null
            if [[ \$? -ne 0 ]]; then
                echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
                let download_thirdparty++

            fi
        else
            echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
            let download_thirdparty++

      fi
	 
	else
		remote_md5=\$(curl -s \"$url\" | md5sum | awk '{print \$1}')
        md5_local=\$(md5sum \"\$filename\" | awk '{print \$1}')
		if [ \"\$md5_remote\" != \"\$md5_local\" ]; then
            if wget -q  --spider \"\$url\"; then
				rm -f \"\$filename\"  
				wget  \"\$url\"   &>/dev/null
			    if [[ \$? -ne 0 ]]; then
					echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
					let download_thirdparty++
				fi
			else
				echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
				let download_thirdparty++
			
            fi

		fi
    fi
done
!


if [[ \$download_thirdparty -ge 1 ]];then
        exit
else
	echo -e \"$COL_START${GREEN}下载Klustron分布式数据库组件成功$COL_END\"        
fi
"

}


function kunlun_package(){

sudo -E su - ${klustron_info[0]} -c  "

if [[ -d ${klustron_info[1]} ]];then

	cd ${klustron_info[1]}/clustermgr/

	lan_net='http://192.168.0.104:14000'
	wal_net='http://zettatech.tpddns.cn:14000'
	#date_time='archive/2024-04-08/'

	if nc -z 192.168.0.104 14000; then
		urls=(
		\"\$lan_net/dailybuilds_x86_64/docker-images/\${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-cdc-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-server-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
		)

	else

		urls=(
		\"\$wal_net/dailybuilds_x86_64/docker-images/\${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-cdc-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-server-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/\${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
		)


	fi

else
  echo -e \"$COL_START$RED目录${klustron_info[1]}不存在$COL_END\"
  exit
 
fi
	

echo -e \"$COL_START${YELLOW}正在下载Klustron分布式数据库安装包,请勿中断........$COL_END\" 

for url in \"\${urls[@]}\"; do
    filename=\$(basename \"\$url\")
    if  [[ ! -f \$filename ]];then
      if wget -q  --spider \"\$url\"; then
            wget  \"\$url\"   &>/dev/null
            if [[ \$? -ne 0 ]]; then
                echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
                let download_package++

            fi
        else
            echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
            let download_package++

      fi
	 
	else
		remote_md5=\$(curl -s \"$url\" | md5sum | awk '{print \$1}')
        md5_local=\$(md5sum \"\$filename\" | awk '{print \$1}')
		if [ \"\$md5_remote\" != \"\$md5_local\" ]; then
            if wget -q  --spider \"\$url\"; then
				rm -f \"\$filename\"  
				wget  \"\$url\"   &>/dev/null
			    if [[ \$? -ne 0 ]]; then
					echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
					let download_package++
				fi
			else
				echo -e \"$COL_START${RED}下载\$filename失败$COL_END\"
				let download_package++
			
            fi

		fi
    fi
done



if [[ -s kunlun-storage-${klustron_VERSION}.tgz ]]; then
    tar xf kunlun-storage-${klustron_VERSION}.tgz && \
    cd kunlun-storage-${klustron_VERSION}/dba_tools && \
    sed -ri 's#^innodb_page_size=.*\$#innodb_page_size=16384#g' template-rbr.cnf && \
    cd ../.. && \
    rm -f kunlun-storage-${klustron_VERSION}.tgz && \
    tar -czf kunlun-storage-${klustron_VERSION}.tgz kunlun-storage-${klustron_VERSION} && \
    rm -fr kunlun-storage-${klustron_VERSION}
    if [[ \$? -ne 0 ]]; then
        echo -e \"$COL_START$RED请检查文件kunlun-storage-${klustron_VERSION}.tgz重新打包失败$COL_END\"
        exit
    fi
else
	echo -e \"$COL_START$RED文件kunlun-storage-${klustron_VERSION}.tgz不存在$COL_END\"
	exit
fi




if [[ \$download_package -ge 1 ]];then
        exit
else
	echo -e \"$COL_START${GREEN}下载Klustron分布式数据库安装包成功$COL_END\"
	
fi
"


}





function install_script(){

sudo -E su - ${klustron_info[0]} -c  "

if [[ -d ${klustron_info[1]} ]];then

	cd ${klustron_info[1]}
	
	for i in install clean start stop
	do
	
		if  command -v python &> /dev/null; then
				python setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i  &> /dev/null
				if [[ \$? -ne 0 ]];then
						echo -e \"$COL_START$RED执行python setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i有误$COL_END\"
		
				fi
		elif  command -v python2 &> /dev/null; then
				python2 setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i  &> /dev/null
				if [[ \$? -ne 0 ]];then
						echo -e \"$COL_START$RED执行python2 setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i有误$COL_END\"
		
				fi
		
		elif  command -v python3 &> /dev/null; then
				python3 setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i  &> /dev/null
				if [[ \$? -ne 0 ]];then
						echo -e \"$COL_START$RED执行python3 setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i有误$COL_END\"
		
				fi
		
		else
			echo  -e \"${GREEN_COLOR}========================================================$RES\"
			echo  -e \"$RED_COLOR_UF错误:$RES\"
			echo  -e \"${YELLOW_COLOR}python命令不存在,请安装python$RES\"
			echo  -e \"${GREEN_COLOR}========================================================$RES\"
			exit 1
		fi




	done
	
else
  echo -e \"$COL_START$RED目录${klustron_info[1]}不存在$COL_END\"
  exit
		
fi

"
}




function install_cluster(){

sudo -E su - ${klustron_info[0]} -c  "

if [[ -d ${klustron_info[1]} ]];then

	cd ${klustron_info[1]}
	
	echo -e \"$COL_START${YELLOW}正在安装Klustron分布式数据库集群需要一点时间,请耐心等待,请勿中断.......$COL_END\"  
	
	if [[ -s clustermgr/clean.sh  && -s clustermgr/install.sh ]];then 
		if bash clustermgr/clean.sh &>/dev/null && bash clustermgr/install.sh ;then  
		#if true;then
		echo -e \"$COL_START${YELLOW}=======================================$COL_START${GREEN}Successful${COL_END}$COL_START${YELLOW}====================================$COL_END\" 
		echo \"███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗\"
    echo \"██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝\"
    echo \"███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗\"
    echo \"╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║\"
    echo \"███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║\"
    echo \"╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝\"
    echo \"                              https:// www.kunlunbase.com\"

		echo -e \"$COL_START${GREEN} 
恭喜您已经重新安装好了Klustron分布式数据库集群
我们提供了XPanel GUI工具软件，让DBA通过点击鼠标就可以轻松完成所有的数据库运维管理工作
XPANEL 访问地址：COL_END\"

for i in ${klustron_xpanel[*]}
do
echo -e  \"$COL_START${GREEN}http://\$i/KunlunXPanel/$COL_END\"
done

echo -e \"$COL_START${GREEN}
初始化账户：super_dba
初始化密码：super_dba
XPANEL详细使用手册请阅读官方文档http://doc.klustron.com/zh/XPanel_Manual.html
	$COL_END\" 
	echo -e \"$COL_START${YELLOW}=====================================================================================$COL_END\" 
	else
			echo -e \"$COL_START${RED}安装失败,请联系泽拓科技售后人员$COL_END\"  
			exit
		fi
	
	
	else
		echo -e \"$COL_START${RED}安装失败,集群安装脚本不存在$COL_END\"  
		exit
	fi



else
  echo -e \"$COL_START$RED目录${klustron_info[1]}不存在$COL_END\"
  exit


fi 
"
}



function __main() {
kunlun_user_env
kunlun_thirdparty
kunlun_package
install_script
install_cluster

}

__main