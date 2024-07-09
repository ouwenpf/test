#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'

klustron_user=$(ls -l $0 | awk '{print $3}')
basedir="$HOME/softwares/cloudnative/cluster"
#current_dir=$(dirname "$(dirname "$(readlink -f "$0")")")
klustron_VERSION='1.3.1'
klustron_xpanel=($(sudo jq -r '.xpanel.nodes[] | "\(.ip):\(.port)"'  $basedir/klustron_config.json))

klustron_info=("$klustron_user" "$basedir" "$klustron_VERSION")


if [[ ${klustron_info[0]} != "$USER" ]];then
  echo -e "$COL_START$RED 请在${klustron_user}用户下执行脚本$0$COL_END"
  exit
fi  

if ! curl -s --head www.kunlunbase.com | head -n 1 | grep "200 OK" > /dev/null; then
    echo  -e "$COL_START$RED当前主机网络异常$COL_END"
    exit
    
fi







function upgrade_package_download(){

sudo -E su - ${klustron_info[0]} -c  "

if [[ -d ${klustron_info[1]} ]];then

	cd ${klustron_info[1]}/clustermgr/

	lan_net='http://192.168.0.104:14000'
	wal_net='http://zettatech.tpddns.cn:14000'
	#date_time='archive/2024-04-08/'

	if nc -z 192.168.0.104 14000; then
		urls=(
		\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-server-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/docker-images/${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"		
		\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cdc-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
		)

	else

		urls=(
		\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-server-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/docker-images/${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"		
		\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cdc-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
		)


	fi

else
  echo -e \"$COL_START$RED目录${klustron_info[1]}不存在$COL_END\"
  exit
 
fi
	


# 下载和更新软件包

echo -e \"$COL_START${YELLOW}正在下载Klustron分布式数据库对应更新包,请勿中断........$COL_END\" 

for url in \"\${urls[$(($upgrade_id-1))]}\"; do
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
		remote_md5=\$(curl -s \"$url\" | awk '{print \$1}')
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




if [[ \$download_package -ge 1 ]];then
        exit
else
	echo -e \"$COL_START${GREEN}已成功下载Klustron分布式数据库对应更新包$COL_END\"
	
fi
"


}




function upgrade_component_id(){

sudo -E su - ${klustron_info[0]} -c  "


if [[ -s ${klustron_info[1]}/klustron_config.json  ]];then

	cd ${klustron_info[1]} && \
	cp klustron_config.json  upgrade_klustron_config.json 
	if command -v jq  &> /dev/null; then
		if  [[ $upgrade_id -eq 1 ]];then
			jq '.node_manager.upgrade_server = true' upgrade_klustron_config.json  > temp.upgrade_klustron_config.json && mv temp.upgrade_klustron_config.json upgrade_klustron_config.json 
		elif [[ $upgrade_id -eq 2 ]];then
			jq '.node_manager.upgrade_storage = true' upgrade_klustron_config.json  > temp.upgrade_klustron_config.json && mv temp.upgrade_klustron_config.json upgrade_klustron_config.json 
		elif [[ $upgrade_id -eq 3 ]];then
			jq '.xpanel.upgrade_all = true' upgrade_klustron_config.json  > temp.upgrade_klustron_config.json && mv temp.upgrade_klustron_config.json upgrade_klustron_config.json
		elif [[ $upgrade_id -eq 4 ]];then
			jq '.cluster_manager.upgrade_all = true' upgrade_klustron_config.json  > temp.upgrade_klustron_config.json && mv temp.upgrade_klustron_config.json upgrade_klustron_config.json 
		elif [[ $upgrade_id -eq 5 ]];then
			jq '.node_manager.upgrade_nodemgr = true' upgrade_klustron_config.json  > temp.upgrade_klustron_config.json && mv temp.upgrade_klustron_config.json upgrade_klustron_config.json
		fi	
	else
		echo -e \"$COL_START${RED}jq命令不存在,请安装$COL_END\"
		exit  $upgrade_id
	fi
	
	
	if  command -v python &> /dev/null; then
			python setup_cluster_manager.py  --config=upgrade_klustron_config.json    --product_version=${klustron_info[2]} --action=upgrade --upgrade_version=${klustron_info[2]}   &> /dev/null
			if [[ \$? -ne 0 ]];then
					echo -e \"$COL_START${RED}执行python setup_cluster_manager.py  --config=upgrade_klustron_config.json  --product_version=${klustron_info[2]} --action=upgrade有误$COL_END\"
					exit $upgrade_id
	
			fi
	
	else
			echo -e \"$COL_START${RED}python命令不存在,请安装python$COL_END\"
			exit $upgrade_id
	fi




	
else
  echo -e \"$COL_START$RED文件${klustron_info[1]}/klustron_config.json不存在$COL_END\"
  exit $upgrade_id
		
fi

"
}








function upgrade_operation(){

sudo -E su - ${klustron_info[0]} -c  "

if [[ -d ${klustron_info[1]} ]];then

	cd ${klustron_info[1]} 
	
	echo -e \"$COL_START${YELLOW}正在更新Klustron分布式数据库对应的组件,请耐心等待,请勿中断.......$COL_END\"  
	
	if [[ -s clustermgr/upgrade.sh  ]];then 
		if bash clustermgr/upgrade.sh ;then  
		#if true;then
	echo \"███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗\"
    echo \"██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝\"
    echo \"███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗\"
    echo \"╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║\"
    echo \"███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║\"
    echo \"╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝\"
    echo \"                               https://www.kunlunbase.com\"


		else
			echo -e \"$COL_START${RED}升级失败,请联系泽拓科技售后人员$COL_END\"  
			exit  
		fi
	
	
	else
		echo -e \"$COL_START${RED}安装失败,升级脚本不存在$COL_END\"  
		exit  
	fi



else
  echo -e \"$COL_START$RED目录${klustron_info[1]}不存在$COL_END\"
  exit  


fi 
"
}



function __main() {


echo -e "$COL_START$YELLOW 
                        更新列表:
----------------------------------------------------- $COL_END$COL_START$GREEN 
1. upgrade_server

2. upgrade_storage
 
3. upgrade_xpanel

4. upgrade_clustmgr
   
5. upgrade_nodemgr    $COL_END$COL_START$YELLOW 
------------------------------------------------------$COL_END"


while true; do
    read  -e -p "请输入更新序号 (输入 'q' 或 'Q' 退出): " upgrade_id

    case $upgrade_id in 
    1)
        upgrade_component_id
        if [[ $? -eq $upgrade_id ]];then
           exit
        fi        
        break
        ;;
    2)
        upgrade_component_id
        if [[ $? -eq $upgrade_id ]];then
           exit
        fi        
        break
        ;;
    3)
        upgrade_component_id
         if [[ $? -eq $upgrade_id ]];then
           exit
        fi       
        break
        ;;
    4)
        upgrade_component_id
        if [[ $? -eq $upgrade_id ]];then
           exit
        fi        
        break
        ;;
    5)
        upgrade_component_id
        if [[ $? -eq $upgrade_id ]];then
           exit
        fi
        break
        ;;
    [qQ])
        exit
        ;;
    *) 
       
        ;;
    esac
done



upgrade_package_download
upgrade_operation
}

__main