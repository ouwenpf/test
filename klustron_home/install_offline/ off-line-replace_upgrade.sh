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

urls=(
"kunlun-server-${klustron_VERSION}.tgz" 
"kunlun-storage-${klustron_VERSION}.tgz" 
"kunlun-xpanel-${klustron_VERSION}.tar.gz" 
"kunlun-cluster-manager-${klustron_VERSION}.tgz" 
"kunlun-node-manager-${klustron_VERSION}.tgz" 
)


if [[ ${klustron_info[0]} != "$USER" ]];then
  echo -e "$COL_START$RED 请在${klustron_user}用户下执行脚本$0$COL_END"
  exit
fi  









function upgrade_component_id(){

sudo -E su - ${klustron_info[0]} -c  "


if [[ ! -s ${klustron_info[1]}/clustermgr/${urls[$(($upgrade_id-1))]} ]];then
	echo -e \"$COL_START$RED文件${klustron_info[1]}/clustermgr/${urls[$(($upgrade_id-1))]}不存在$COL_END\"
	exit $upgrade_id
fi







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
			python setup_cluster_manager.py  --config=upgrade_klustron_config.json    --product_version=${klustron_info[2]} --action=upgrade   &> /dev/null
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




upgrade_operation
}

__main