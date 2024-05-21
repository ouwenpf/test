#!/bin/bash


function configure_global(){

# 颜色设置
RES='\e[0m'
BLACK_COLOR='\e[30m'        # 黑色字 
RED_COLOR='\e[31m'          # 红色字
GREEN_COLOR='\e[32m'        # 绿色字
YELLOW_COLOR='\e[33m'	    # 黄色字
BLUE_COLOR='\e[34m'         # 蓝色字
PURPLE_COLOR='\e[35m'       # 紫色字
SKY_BLUE_COLOR='\e[36m'     # 天蓝色字
WHITE_COLOR='\e[37m'        # 白色字
RED_COLOR_UF='\e[4;5;31m'   # 红色下划线闪烁

rnu=$((RANDOM % 21))


if command -v curl &> /dev/null; then
	if ! curl -s --head www.kunlunbase.com | head -n 1 | grep "200 OK" > /dev/null; then
		echo  -e "$RED_COLOR当前主机无法连接外网$RES"
		exit 
	fi

elif command -v ping &> /dev/null; then
	if ! ping -c 3 www.kunlunbase.com > /dev/null 2>&1; then
		echo  -e "$RED_COLOR当前主机无法连接外网$RES"
		exit 
 
	fi

else
    echo -e "${RED_COLOR}warning:$RES"
    echo -e "$YELLOW_COLOR无法判断主机外网络连接状态$RES"
	echo -e "$YELLOW_COLOR使用命令安装 sudo yum -y install iputils curl$RES"
    exit 
fi


# 安装必须的命令
for i in  expect dos2unix jq nc git; do
   if ! command -v "$i" &> /dev/null; then
       sudo yum install -y $i &>/dev/null
       if [[ $? -ne 0 ]]; then
	        echo  -e "${RED_COLOR}$i命令安装失败$RES"
			exit
       fi
   fi
done


}




function klustron_ip() {
    declare -a machines_ip_list=()
    declare -A seen

    validate_ip() {
        local ip=$1
        local regex="^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$"

        if ! [[ $ip =~ $regex ]]; then
            return 1
        fi
    }

    while true; do

        read -e -p "请输入服务器IP以空格分隔 (输入 'q' 或 'Q' 退出): " ip_list
        if [[ $ip_list =~ [qQ] ]]; then
            exit
        fi

        if [ -z "$ip_list" ] || [ ! "$ip_list" ]; then
            echo -e "${RED_COLOR}输入不能为空，请重新输入。${RES}"  >&2
            #echo "输入不能为空，请重新输入。"  >&2
            continue
        fi

        IFS=' ' read -e -ra new_ips <<< "$ip_list"
        if [ "${#new_ips[@]}" -lt 3 ]; then
            echo -e "${RED_COLOR}输入的IP不能少于三个，请重新输入。${RES}"  >&2
            #echo "输入的IP不能少于三个，请重新输入。" >&2
            continue
        fi

        local duplicate_found=false
        local duplicate_ips=()
        for element in "${new_ips[@]}"; do
            if [[ -n "${seen[$element]}" ]]; then
                duplicate_ips+=("$element")
                duplicate_found=true
            else
                seen["$element"]=1
            fi
        done

        if [ "$duplicate_found" = true ]; then
            echo -e "${RED_COLOR}以下IP地址重复输入:${RES}"  >&2
            #echo "以下IP地址重复输入:"   >&2
            printf '%s\n' "${duplicate_ips[@]}"   >&2
     			  new_ips=()
			      seen=()
            continue
        fi

        # 判断每个IP的合法性
        local invalid_ips=()
        for ip in "${new_ips[@]}"; do
            if ! validate_ip "$ip"; then
                invalid_ips+=("$ip")
            fi
        done

        if [ "${#invalid_ips[@]}" -gt 0 ]; then
            echo -e "${RED_COLOR}输入的IP中存在非法的IP地址，请重新输入。${RES}"  >&2
            echo -e "${RED_COLOR}非法的IP地址: ${invalid_ips[@]}${RES}"  >&2
            
            #echo "输入的IP中存在非法的IP地址，请重新输入。" >&2
            #echo "非法的IP地址: ${invalid_ips[@]}"   >&2
     			  new_ips=()
			      seen=()
            continue
        fi

        # 如果通过所有检查，将IP添加到数组中
        machines_ip_list=("${new_ips[@]}")

        break
    done

    # 将IP列表作为返回值返回
    echo "${machines_ip_list[@]}"
}















#函数检查机器ssh端口和root密码是否正确
function check_machines_sshport_passwd(){
# 检查ssh端口是否通
count_host_sshport=0
count_machines_passwd=0


echo  -e "$YELLOW_COLOR正在检查系统环境.....$RES"
for i in  ${machines_ip_list[@]}
do

	    
    if ! nc -w 3 -z  $i ${control_machines[2]};then 
      echo -e "$RED_COLOR主机${i} SSH端口${sshport}有异常,无法连接,请检查网络和端口$RES" 
      #变量接收不通的机器数量
      let count_host_sshport++
      continue  
    fi
    
    
   


done

#判断变量是否大于等于1,成立表示有机器ssh端口不通,脚本退出
if [[ $count_host_sshport -ge 1 ]];then
  exit
fi






#检查用户名和密码是否正确
for i in  ${machines_ip_list[@]}
do

    
         
# 探测用户名和密码是否正确         
  expect <<EOF  >/dev/null 2>&1
  
  spawn ssh -p${control_machines[2]} ${control_machines[0]}@${i} "echo Password is correct" 
  expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" {
        send -- {${control_machines[1]}}
		send "\r"
        exp_continue
    }
    "Password is correct" {
        puts "Password is correct"
        exit 0
    }
    timeout {
        puts "Connection timed out or password is incorrect"
        exit 1
    }
    eof {
        puts "Failed to connect to remote host"
        exit 1
    }
    "*assword incorrect*" {
        puts "Password is incorrect"
        exit 1
    }
}



expect eof

EOF

   
  if [[ $? -ne 0 ]];then
    echo -e "$RED_COLOR${control_machines[0]}@${i}连接异常无法连接,请检用户名或密码$RES"
    #变量接收用户名或者密码不匹配机器数量
    let count_machines_passwd++
   
  fi 


done

# 判断变量值如果大于1表示有主机用户名和密码不匹配,脚本退出

if [[ $count_machines_passwd -ge 1 ]];then
  exit
fi





}








#函数检查机器的架构是否一致
function check_arch(){

declare -A server_arch
for i in "${machines_ip_list[@]}"
do

   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo uname -m"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
            eof { exit }
        }
        expect eof
EOF
)


server_arch["$i"]=$(echo "$output"|dos2unix|sed '1d'|egrep -v 'password')
first_arch=$(sudo uname -m|dos2unix)

if [[ "${server_arch["$i"]}" != "$first_arch" ]]; then
   let  count_arch++
fi


done


#判断变量是否大于等于1,成立表示有机器架构不一样,脚本退出
if [[ $count_arch -ge 1 ]];then
  echo -e "$RED_COLOR}主机架构不一致$RES"
  exit
fi


}



#函数检查机器的OS是否一致
function check_os(){

declare -A server_os

for i in "${machines_ip_list[@]}"
do

   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh   -p${control_machines[2]} ${control_machines[0]}@$i 2>/dev/null  "cat /etc/os-release |egrep  -iw 'ID'"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
            eof { exit }
        }
        expect eof
EOF
)



server_os["$i"]=$(echo "$output"|dos2unix|sed '1d'|egrep -v 'password'|egrep  -iw 'ID')

first_os=${server_os[${machines_ip_list[0]}]}


if [[ "${server_os["$i"]}" != "$first_os" ]]; then
   let  count_os++
fi


done


#判断变量是否大于等于1,成立表示有机器系统不一致,脚本退出
if [[ $count_os -ge 1 ]];then
  echo -e "$RED_COLOR主机系统不一致$RES"
  exit
fi



}



#函数检查机器的时区是否一致

function check_zone(){

declare -A timezone
for i in "${machines_ip_list[@]}"
do
    # 执行initialize.sh脚本
   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo timedatectl | grep 'Time zone' |awk -F ':' '{print $2}'|awk '{print $1}'"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
            eof { exit }
        }
        expect eof
EOF
)


timezone["$i"]=$(echo "$output"|dos2unix|egrep -v 'password'|awk -F 'zone:' '{print $2}'|awk -F '[ ]+' '{print $2}')

first_timezone=${timezone[${machines_ip_list[0]}]}

if [[ "${timezone["$i"]}" != "$first_timezone" ]]; then
   let  count_timezone++
fi


done


#判断变量是否大于等于1,成立表示有机器ssh端口不通,脚本退出
if [[ $count_timezone -ge 1 ]];then
  echo -e "$RED_COLOR主机时区不一致$RES" 
  exit
fi

}



function check_klustron_running(){

for i in ${machines_ip_list[@]}; do
output=$(expect <<EOF
  set timeout 10
  spawn ssh -p${control_machines[2]} ${control_machines[0]}@${i} "ps aux | grep -w '${klustron_info[1]}/kunlun-node-manager-${klustron_VERSION}' | grep -v grep|wc -l"
   
  	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { 
			 send -- {${control_machines[1]}}
			 send "\n"
		
		}
		eof { exit }
	
	}
 

	expect eof

EOF
)


#expect输出是以Windows格式,需要使用dos2unix工具转换
result=$(echo "$output"|dos2unix| awk 'NR==3{print $0}')

if [[ $result == 2 ]];then
  let count_klustron_exist++
  echo -e "$RED_COLOR主机$i上已经安装有klustron数据库无法安装..........$RES" 
  
fi


done



# 判断变量值如果大于等于1表示有主机存在node_mgr运行进程,脚本退出
if [[ $count_klustron_exist -ge 1 ]];then 
  exit
fi


}







function check_kunlun_user(){


privileges_line="${klustron_info[0]}   ALL=(ALL)       NOPASSWD: ALL"

if ! id ${klustron_info[0]} &>/dev/null; then 
  sudo useradd ${klustron_info[0]} &>/dev/null && \
  if [[ $? == 0 ]]; then
      if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
          sudo sed -i "/^root/a$privileges_line" /etc/sudoers &>/dev/null
          if [[ $? == 0 ]]; then
              echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
		  else
			  echo -e "${RED_COLOR}${klustron_info[0]}kunlun_sudo-Failed${RES}"
			  exit			  
          fi
      fi
  else
      echo -e "${RED_COLOR}${klustron_info[0]}kunlun_user-Failed${RES}"
      exit
  fi
  
else

  if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
      sudo sed -i "/^root/a$privileges_line" /etc/sudoers  &>/dev/null
      if [[ $? == 0 ]]; then
          echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
	  else
		  echo -e "${RED_COLOR}${klustron_info[0]}kunlun_sudo-Failed${RES}"
		  exit	
      fi
  else
      echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
  fi


fi

}





# 获取昆仑用户家目录路径,家目录非/home/user
function check_kunlun_home(){

function home_user(){
    
    kunlun_home_dir=$(sudo -E su - ${klustron_info[0]} -c "eval echo ~$SUDO_USER")
    # 将 kunlun_home_dir 变量的值返回到脚本中
    echo $kunlun_home_dir
}

if [[ ! -z "$(home_user)" ]];then
	kunlun_home=$(home_user)
	klustron_info[1]=$(home_user)/klustron
else
	echo -e "$RED_COLOR无法获取${klustron_info[0]}用户环境变量$RES" 
	exit 
fi


}





# 检查数据库安装程序
function check_kunlun_setup(){


sudo -E su - ${klustron_info[0]} -c "

#echo -e \"\e[33m正在下载昆仑安装程序......\e[0m\"  #&>/dev/null
echo -e \"${YELLOW_COLOR}正在下载昆仑安装程序......$RES\"

if [[ ! -d  \$HOME/softwares/cloudnative ]]; then
    git clone https://gitee.com/zettadb/cloudnative.git \$HOME/softwares/cloudnative &>/dev/null
    if [[ \$? -eq 0 ]]; then 
        echo -e \"${GREEN_COLOR}昆仑安装程序下载成功$RES\"
    else 
        echo -e \"${RED_COLOR}昆仑安装程序下载失败$RES\"
        exit
    fi
else
    echo -e \"${GREEN_COLOR}昆仑安装程序下载成功$RES\"
fi
"

}





# 控制机上面创建kunlun用户秘钥
function configure_kunlun_skey(){

sudo -E su - ${klustron_info[0]} -c "
    if [[ ! -s \$HOME/.ssh/id_rsa || ! -s \$HOME/.ssh/id_rsa.pub ]]; then
        rm -f \$HOME/.ssh/id_rsa \$HOME/.ssh/id_rsa.pub  && \
        ssh-keygen -t rsa -N \"\" -f \$HOME/.ssh/id_rsa -q && \
        cat \$HOME/.ssh/id_rsa.pub >> \$HOME/.ssh/authorized_keys && \
        chmod 600 \$HOME/.ssh/authorized_keys
    else
        if [[ ! -s \$HOME/.ssh/authorized_keys ]]; then
            cat \$HOME/.ssh/id_rsa.pub > \$HOME/.ssh/authorized_keys && \
            chmod 600 \$HOME/.ssh/authorized_keys
        fi
    fi

    
"



sudo -E su - ${klustron_info[0]} -c "



if ! grep -q \"${klustron_info[1]}/env.sh\"   ~/.bashrc ;then

cat << 'EOF' >> ~/.bashrc
${klustron_info[0]}_env_${rnu}(){

  if [[ -f ${klustron_info[1]}/env.sh ]];then

        if  grep -q 'envtype=\"\${envtype:-no}\"' ${klustron_info[1]}/env.sh;then
            sed -ri 's!\\$\{envtype:-no\}!all!g'  ${klustron_info[1]}/env.sh && \
            source ${klustron_info[1]}/env.sh
        else
            source ${klustron_info[1]}/env.sh
        fi


  fi 




}


${klustron_info[0]}_env_${rnu}

EOF

fi
"


}





function configure_kunlun_config(){

config_name="klustron_config.json"

# 生成 machines 节点
machines=""
for ip in "${machines_ip_list[@]}"; do
    machines+=$(cat <<EOF
    
    {
            "ip": "$ip",
            "sshport": ${control_machines[2]},
            "basedir": "$basedir",
            "user": "${klustron_info[0]}"
    },
EOF
)
done
machines="${machines%,}"  # 移除最后一个对象后面的逗号 



# 随机选择3个 IP 作为 meta.nodes 和 cluster_manager.nodes 的 IP
selected_ips=()
while [ ${#selected_ips[@]} -lt 3 ]; do
    random_index=$((RANDOM % ${#machines_ip_list[@]}))
    ip="${machines_ip_list[$random_index]}"
    if [[ ! " ${selected_ips[@]} " =~ " ${ip} " ]]; then
        selected_ips+=("$ip")
    fi
done




# 生成 meta.nodes 节点
meta_nodes=""
for ip in "${selected_ips[@]}"; do
    meta_nodes+=$(cat <<EOF
    
    {
                "ip": "$ip",
                "port": 56001
    },
EOF
)
done
meta_nodes="${meta_nodes%,}"  # 移除最后一个对象后面的逗号




# 生成 cluster_manager.nodes 节点
cluster_manager_nodes=""
for ip in "${selected_ips[@]}"; do
    cluster_manager_nodes+=$(cat <<EOF
    
    {
                "ip": "$ip",
                "brpc_http_port": 58000,
                "brpc_raft_port": 58001,
                "prometheus_port_start": 59010
    },
EOF
)
done
cluster_manager_nodes="${cluster_manager_nodes%,}"   # 移除最后一个对象后面的逗号



# 生成 node_manager.nodes 节点
node_manager_nodes=""
for ip in "${machines_ip_list[@]}"; do
    node_manager_nodes+=$(cat <<EOF
    
    {
                "ip": "$ip",
                "brpc_http_port": 58002,
                "tcp_port": 58003,
                "prometheus_port_start": 58010,
                "storage_portrange": "57000-58000",
                "server_portrange": "47000-48000"
    },
EOF
)
done
node_manager_nodes="${node_manager_nodes%,}"  # 移除最后一个对象后面的逗号



# 随机选择一个 IP 作为 xpanel 的 ip
random_xpanel_ip=${machines_ip_list[$RANDOM % ${#machines_ip_list[@]}]}

# 生成 xpanel 节点
xpanel=$(cat <<EOF
"xpanel": {
    "upgrade_all": false,
    "imageType": "file",
    "nodes": [
                {
                "ip": "$random_xpanel_ip",
                "port": 18080
                }
        ]

    }
EOF
)





if sudo test ! -s $kunlun_home/softwares/cloudnative/cluster/$config_name ;then
# 生成完整的 JSON 配置文件

sudo bash -c "cat <<EOF > $kunlun_home/softwares/cloudnative/cluster/$config_name
{
    \"machines\": [
    $machines
    ],
    \"meta\": {
        \"ha_mode\": \"rbr\",
        \"config\": {
            \"innodb_buffer_pool_size\": \"1024MB\",
            \"innodb_page_size\": 16384,
            \"max_binlog_size\": 1073741824,
            \"lock_wait_timeout\": 1200,
            \"innodb_lock_wait_timeout\": 1200
        },
        \"nodes\": [
            $meta_nodes
        ]
    },
    \"cluster_manager\": {
        \"upgrade_all\": false,
        \"nodes\": [
            $cluster_manager_nodes
        ]
    },
    \"node_manager\": {
          \"upgrade_nodemgr\": false,
    	  \"upgrade_server\": false,
    	  \"upgrade_storage\": false,
          \"nodes\": [
            $node_manager_nodes
        ]
    },
    $xpanel
}
EOF"  && \

	sudo chown ${klustron_info[0]}:${klustron_info[0]} $kunlun_home/softwares/cloudnative/cluster/$config_name


else

	sudo cp $kunlun_home/softwares/cloudnative/cluster/$config_name{,.tmp} && \
	sudo chown ${klustron_info[0]}:${klustron_info[0]} $kunlun_home/softwares/cloudnative/cluster/$config_name.tmp

fi

klustron_xpanel=($(sudo jq -r '.xpanel.nodes[] | "\(.ip):\(.port)"'  $kunlun_home/softwares/cloudnative/cluster/$config_name))
klustron_ip=($(sudo jq -r '.xpanel.nodes[] | "\(.ip)"'  $kunlun_home/softwares/cloudnative/cluster/$config_name))
}






function host_initialize(){

env_file="os_centos_env.sh"

#if sudo test -s $kunlun_home/softwares/cloudnative/cluster/klustron_home/install_online/scripts/$env_file ;then
#  sudo cp -ra $kunlun_home/softwares/cloudnative/cluster/klustron_home/install_online/scripts/$env_file  /tmp/  && \
#  sudo chown ${control_machines[0]}:${control_machines[0]}  /tmp/$env_file
  
if sudo test -s ./scripts/$env_file ;then
  sudo cp -ra ./scripts/$env_file  /tmp/  && \
  sudo chown ${control_machines[0]}:${control_machines[0]}  /tmp/$env_file


  for i in "${machines_ip_list[@]}"
  do
    # 复制 $config_file到远程主机
output=$(expect <<EOF
  set timeout 3
  spawn  scp -rp -P${control_machines[2]} /tmp/$env_file ${control_machines[0]}@$i:/tmp/

        expect {
                "yes/no" { send "yes\n"; exp_continue }
                "password" {
                         send -- {${control_machines[1]}}
                         send "\n"
				
                }
				eof { exit }

        }


        expect eof

EOF
)


  result=$(echo  "$output"|grep  'Permission denied'|wc -l)

  if [[ $result -eq 1 ]];then
    echo -e "${RED_COLOR}文件$env_file拷贝到${control_machines[0]}@$i失败$RES"
    #变量接收分发脚本失败的函数
    let count_host_initialize++
  fi

  

  done
  
  # 判断变量值如果大于等于1表示有机器分发脚本失败,为了保证每个机器安装顺利进行,脚本退出
  if [[ $count_host_initialize -ge 1 ]];then 
    exit
  else
    echo -e "${GREEN_COLOR}第三步:文件拷贝成功$RES" &>/dev/null
  fi

  
  
  
else
  echo -e "${RED_COLOR}文件$env_file不存在$RES"
  exit 
fi



}







# 在安装昆仑数据库的机器上初始化环境
function execute_initialize(){

echo  -e "${YELLOW_COLOR}正在初始化机器需要一点时间,请耐心等待,请勿中断.......$RES" 
echo  -e "${YELLOW_COLOR}========================================================$RES"

for i in "${machines_ip_list[@]}"
do
    # 执行initialize.sh脚本
   output=$(expect <<EOF #&>/dev/null
        set timeout 300
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo bash /tmp/$env_file  ${klustron_info[@]} ${klustron_ip[@]} && sudo rm -f /tmp/$env_file"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            
            }
            eof { exit }
        }
        expect eof
EOF
)


 result_ip=$(printf "%s" "$output" | tr -cd '[:print:]'|awk -F '@'  '{print $2}'|awk '{print $1}')
 result_error=$(printf "%s" "$output" | tr -cd '[:print:]'|awk -F 'password:' '{print $2}'|xargs -n 1)
 result_array=("$result_ip" "$result_error")


<<!
 for k in "${result_array[@]}"; do
    echo -e "${RED_COLOR}$k$RES"
 done
echo  -e "${RED_COLOR}========================================================$RES"
!


if echo $result_error|grep -wq 'Network-Erro' ;then 
	echo  -e  "${RED_COLOR}主机$i:$RES" 
	echo  -e  "${RED_COLOR}网络异常$RES" 
	let Network-Erro++
	
echo  -e "${YELLOW_COLOR}========================================================$RES"
elif echo $result_error|grep -wq 'Conn-Status' ;then 
	echo  -e  "${RED_COLOR}主机$i:$RES" 
	echo  -e  "${RED_COLOR}网络状态无法判断$RES" 
	echo  -e  "${RED_COLOR}使用命令安装:sudo yum -y install iputils curl$RES" 
	let Conn-Status++	
	
echo  -e "${YELLOW_COLOR}========================================================$RES"
elif echo $result_error|grep -wq 'Param-Error' ;then 
	echo  -e  "${RED_COLOR}主机$i:$RES" 
	echo  -e  "${RED_COLOR}参数输入错误$RES" 
	let Param-Error++
	
echo  -e "${YELLOW_COLOR}========================================================$RES"
elif echo $result_error|grep -wq 'kunlun_user-Failed' ;then 
	echo  -e  "${RED_COLOR}主机$i:$RES" 
	echo  -e  "${RED_COLOR}昆仑用户创建失败$RES" 
	let kunlun_user-Failed++
	
echo  -e "${YELLOW_COLOR}========================================================$RES"
elif echo $result_error|grep -wq 'kunlun_sudo-Failed' ;then 
	echo  -e  "${RED_COLOR}主机$i:$RES" 
	echo  -e  "${RED_COLOR}昆仑用户权限设置失败$RES" 
	let kunlun_sudo-Failed++
	
echo  -e "${YELLOW_COLOR}========================================================$RES"
elif echo $result_error|grep -wq 'kunlun_basedir-Failed' ;then 
	echo  -e  "${RED_COLOR}主机$i:$RES" 
	echo  -e  "${RED_COLOR}数据库安装目录创建失败$RES" 
	let kunlun_basedir-Failed++
	
echo  -e "${YELLOW_COLOR}========================================================$RES"
elif echo $result_error|grep -wq 'Exist_Unable_start_Docker' ;then
	echo  -e  "${RED_COLOR}主机$i:$RES" 
	echo  -e  "${RED_COLOR}docker无法启动$RES" 
	let Exist_Unable_start_Docker++
	
echo  -e "${YELLOW_COLOR}========================================================$RES"

else
	echo  -e "${GREEN_COLOR}主机$i:$RES"
	echo  -e "${GREEN_COLOR}Successful$RES"

echo  -e "${YELLOW_COLOR}========================================================$RES"	
fi


done



if [[ ${Network-Erro}  -ge 1 ]];then
	exit
elif [[ ${Conn-Status}  -ge 1 ]];then
	exit 
elif [[ ${Param-Error}  -ge 1 ]];then
	exit 
elif [[ ${kunlun_user-Failed}  -ge 1 ]];then
	exit 
elif [[ ${kunlun_sudo-Failed}  -ge 1 ]];then
	exit 	
elif [[ ${kunlun_basedir-Failed}  -ge 1 ]];then
	exit 	
elif [[ ${Exist_Unable_start_Docker}  -ge 1 ]];then
	exit 
fi


}






function configure_authorized_keys(){

sudo cp -ra $kunlun_home/.ssh /tmp/ && \
sudo chown -R ${control_machines[0]}:${control_machines[0]} /tmp/.ssh

for i in "${machines_ip_list[@]}"
do
    # 复制 .ssh 文件夹到远程主机
    expect <<EOF &>/dev/null
        set timeout 3
        spawn  scp -rp -P${control_machines[2]} /tmp/.ssh ${control_machines[0]}@$i:/tmp/
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
            eof { exit }
        }
        expect eof
EOF



    # 复制 .ssh 文件夹到对应的文件夹
    expect <<EOF &>/dev/null
        set timeout 3
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo cp -ra /tmp/.ssh $kunlun_home"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
            eof { exit }
        }
        expect eof
EOF




    # 更改 .ssh 文件夹的权限
    expect <<EOF &>/dev/null
        set timeout 3
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo chown -R ${klustron_info[0]}:${klustron_info[0]} $kunlun_home/.ssh"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
            eof { exit }
        }
        expect eof
EOF



    # 检查 SSH 连接是否成功
    
 ssh_output=$(sudo -E su - ${klustron_info[0]} -c "ssh -o StrictHostKeyChecking=no -p ${control_machines[2]} ${klustron_info[0]}@$i 2>/dev/null 'echo Successful'")

    if [[ -z "$ssh_output" || "$ssh_output" -ne "Successful" ]]; then
        echo -e "$COL_START${RED}$i主机为klustron数据库用户${klustron_info[0]}配置免密失败$COL_END"
        let count_key_distribution_file++
    fi

done

if [[ $count_key_distribution_file -ge 1 ]] ;then
	echo -e "$COL_START${RED}昆仑用户配置免密失败$COL_END" 
	exit
else
  echo -e "$COL_START${GREEN}第五步:昆仑用户配置免密成功$COL_END"  &>/dev/null
    #删除/tmp/.ssh目录
    for i in "${machines_ip_list[@]}"
    do
      expect <<EOF &>/dev/null
        set timeout 3
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo test -d /tmp/.ssh &&  sudo rm -fr  /tmp/.ssh"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
            eof { exit }
        }
        expect eof
EOF
   done 
fi



}






function kunlun_thirdparty(){

sudo -E su - ${klustron_info[0]} -c  "
cd \$HOME/softwares/cloudnative/cluster/clustermgr/

lan_net='http://192.168.0.104:14000'
wal_net='http://zettatech.tpddns.cn:14000'

if [[ "$(arch)" == "x86_64" ]];then

	if nc -z 192.168.0.104 14000; then
	
		urls=(
			\"\$lan_net/contrib/x86_64/elasticsearch-7.10.1.tar.gz\"
			\"\$lan_net/contrib/x86_64/filebeat-7.10.1-linux-x86_64.tar.gz\"
			\"\$lan_net/contrib/x86_64/kibana-7.10.1.tar.gz\"
			\"\$lan_net/contrib/x86_64/hadoop-3.3.1.tar.gz\"
			\"\$lan_net/contrib/x86_64/jdk-8u131-linux-x64.tar.gz\"
			\"\$lan_net/contrib/common/mysql-connector-python-2.1.3.tar.gz\"
			\"\$lan_net/contrib/x86_64/prometheus.tgz\"
			\"\$lan_net/contrib/x86_64/haproxy-2.5.0-bin.tar.gz\"
		)
	
	else
	
		urls=(
			\"\$wal_net/contrib/x86_64/elasticsearch-7.10.1.tar.gz\"
			\"\$wal_net/contrib/x86_64/filebeat-7.10.1-linux-x86_64.tar.gz\"
			\"\$wal_net/contrib/x86_64/kibana-7.10.1.tar.gz\"
			\"\$wal_net/contrib/x86_64/hadoop-3.3.1.tar.gz\"
			\"\$wal_net/contrib/x86_64/jdk-8u131-linux-x64.tar.gz\"
			\"\$wal_net/contrib/common/mysql-connector-python-2.1.3.tar.gz\"
			\"\$wal_net/contrib/x86_64/prometheus.tgz\"
			\"\$wal_net/contrib/x86_64/haproxy-2.5.0-bin.tar.gz\"
		)
	
	fi

elif [[ "$(arch)" == "aarch64" ]];then


	if nc -z 192.168.0.104 14000; then
	
		urls=(
			\"\$lan_net/contrib/aarch64/elasticsearch-7.13.4.tar.gz\"
			\"\$lan_net/contrib/aarch64/filebeat-7.13.4-linux-arm64.tar.gz\"
			\"\$lan_net/contrib/aarch64/kibana-7.13.4.tar.gz\"
			\"\$lan_net/contrib/aarch64/hadoop-3.3.6-aarch64.tar.gz\"
			\"\$lan_net/contrib/aarch64/jdk-8u371-linux-aarch64.tar.gz\"
			\"\$lan_net/contrib/common/mysql-connector-python-2.1.3.tar.gz\"
			\"\$lan_net/contrib/aarch64/prometheus.tgz\"
			\"\$lan_net/contrib/aarch64/haproxy-2.5.0-bin.tar.gz\"
		)
	
	else
	
		urls=(
			\"\$wal_net/contrib/aarch64/elasticsearch-7.13.4.tar.gz\"
			\"\$wal_net/contrib/aarch64/filebeat-7.13.4-linux-arm64.tar.gz\"
			\"\$wal_net/contrib/aarch64/kibana-7.13.4.tar.gz\"
			\"\$wal_net/contrib/aarch64/hadoop-3.3.6-aarch64.tar.gz\"
			\"\$wal_net/contrib/aarch64/jdk-8u371-linux-aarch64.tar.gz\"
			\"\$wal_net/common/mysql-connector-python-2.1.3.tar.gz\"
			\"\$wal_net/contrib/aarch64/prometheus.tgz\"
			\"\$wal_net/contrib/aarch64/haproxy-2.5.0-bin.tar.gz\"
		)
	
	fi

else
	echo -e \"${RED_COLOR}未知系统架构$RES\" 
	exit

fi



echo -e \"${YELLOW_COLOR}正在下载Klustron分布式数据库相关组件,请勿中断........$RES\" 

for url in \"\${urls[@]}\"; do
    filename=\$(basename \"\$url\")
    if  [[ ! -f \$filename ]];then
      if wget -q  --spider \"\$url\"; then
            wget  \"\$url\"   &>/dev/null
            if [[ \$? -ne 0 ]]; then
                echo -e \"${RED_COLOR}下载\$filename失败$RES\"
                let download_thirdparty++

            fi
        else
            echo -e \"${RED_COLOR}下载\$filename失败$RES\"
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
                echo -e \"${RED_COLOR}下载\$filename失败$RES\"
                let download_thirdparty++

            fi
        else
            echo -e \"${RED_COLOR}下载\$filename失败$RES\"
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
					echo -e \"${RED_COLOR}下载\$filename失败$RES\"
					let download_thirdparty++
				fi
			else
				echo -e \"${RED_COLOR}下载\$filename失败$RES\"
				let download_thirdparty++
			
            fi

		fi
    fi
done
!


if [[ \$download_thirdparty -ge 1 ]];then
        exit
else
	echo -e \"${GREEN_COLOR}下载Klustron分布式数据库组件成功$RES\"        
fi

"

}








function kunlun_package(){

sudo -E su - ${klustron_info[0]} -c  "

cd \$HOME/softwares/cloudnative/cluster/clustermgr/

lan_net='http://192.168.0.104:14000'
wal_net='http://zettatech.tpddns.cn:14000'
#date_time='archive/2024-04-08/'

if [[ "$(arch)" == "x86_64" ]];then

	if nc -z 192.168.0.104 14000; then
		urls=(
			\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-server-${klustron_info[2]}.tgz\"
			\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
			\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
			\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
			\"\$lan_net/dailybuilds_x86_64/docker-images/${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"
			\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
			\"\$lan_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cdc-${klustron_info[2]}.tgz\"
		)
	
	else
	
		urls=(
			\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-server-${klustron_info[2]}.tgz\"
			\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
			\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
			\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
			\"\$wal_net/dailybuilds_x86_64/docker-images/${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"
			\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
			\"\$wal_net/dailybuilds_x86_64/enterprise/${date_time}kunlun-cdc-${klustron_info[2]}.tgz\"
		)
	
	fi
	
elif [[ "$(arch)" == "aarch64" ]];then

	if nc -z 192.168.0.104 14000; then
		urls=(
		\"\$lan_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-server-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
		\"\$lan_net/dailybuilds_aarch64/docker-images/${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"
		\"\$lan_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
		)
	
	else
	
		urls=(
		\"\$wal_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-server-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-storage-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-cluster-manager-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-node-manager-${klustron_info[2]}.tgz\"
		\"\$wal_net/dailybuilds_aarch64/docker-images/${date_time}kunlun-xpanel-${klustron_info[2]}.tar.gz\"
		\"\$wal_net/dailybuilds_aarch64/enterprise/${date_time}kunlun-proxysql-${klustron_info[2]}.tgz\"
		)
	
	fi


else
	echo -e \"${RED_COLOR}未知系统架构$RES\" 
	exit

fi


echo -e \"${YELLOW_COLOR}正在下载Klustron分布式数据库安装包,请勿中断........$RES\" 

for url in \"\${urls[@]}\"; do
    filename=\$(basename \"\$url\")
    if  [[ ! -f \$filename ]];then
      if wget -q  --spider \"\$url\"; then
            wget  \"\$url\"   &>/dev/null
            if [[ \$? -ne 0 ]]; then
                echo -e \"${RED_COLOR}下载\$filename失败$RES\"
                let download_package++

            fi
        else
            echo -e \"${RED_COLOR}下载\$filename失败$RES\"
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
					echo -e \"${RED_COLOR}下载\$filename失败$RES\"
					let download_package++
				fi
			else
				echo -e \"${RED_COLOR}下载\$filename失败$RES\"
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
        echo -e \"${RED_COLOR}请检查文件kunlun-storage-${klustron_VERSION}.tgz重新打包失败$RES\"
        exit
    fi
else
	echo -e \"${RED_COLOR}文件kunlun-storage-${klustron_VERSION}.tgz不存在$RES\"
	exit
fi




if [[ \$download_package -ge 1 ]];then
        exit
else
	echo -e \"${GREEN_COLOR}下载Klustron分布式数据库安装包成功$RES\"
	
fi
"


}



function install_script(){

sudo -E su - ${klustron_info[0]} -c  "

cd \$HOME/softwares/cloudnative/cluster/

for i in install clean start stop
do

if  command -v python &> /dev/null; then
        python setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i  &> /dev/null
        if [[ \$? -ne 0 ]];then
                echo -e \"${RED_COLOR}执行python2 setup_cluster_manager.py --autostart --config=klustron_config.json   --product_version=${klustron_info[2]} --action=\$i有误$RES\"

        fi

else
        echo -e \"${RED_COLOR}python命令不存在,请安装python$RES\"
        exit
fi



done

"
}




function install_cluster(){

sudo -E su - ${klustron_info[0]} -c  "

cd \$HOME/softwares/cloudnative/cluster/

echo -e \"${YELLOW_COLOR}正在安装Klustron分布式数据库集群需要一点时间,请耐心等待,请勿中断.......$RES\"  

if [[ -s clustermgr/clean.sh  && -s clustermgr/install.sh ]];then 
  #if bash clustermgr/clean.sh &>/dev/null && bash clustermgr/install.sh ;then  
  if true;then
    echo -e \"${YELLOW_COLOR}=======================================${GREEN_COLOR}Successful${RES}${YELLOW_COLOR}====================================$RES\" 
	echo \"███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗\"
    echo \"██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝\"
    echo \"███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗\"
    echo \"╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║\"
    echo \"███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║\"
    echo \"╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝\"
    echo -e \"${RED_COLOR}                               https://www.kunlunbase.com$COL_END\"
    echo -e \"${GREEN_COLOR} 
恭喜您已经成功安装好了Klustron分布式数据库集群
我们提供了XPanel GUI工具软件，让DBA通过点击鼠标就可以轻松完成所有的数据库运维管理工作
XPANEL 访问地址：$RES\"

for i in ${klustron_xpanel[*]}
do
 echo -e  \"${GREEN_COLOR}http://\$i/KunlunXPanel/$RES\"
done

echo -e \"${GREEN_COLOR}
初始化账户：super_dba
初始化密码：super_dba
XPANEL详细使用手册请阅读官方文档http://doc.klustron.com/zh/XPanel_Manual.html
    $RES\" 
    echo -e \"${YELLOW_COLOR}=====================================================================================$RES\" 
  else
    echo -e \"${RED_COLOR}安装失败,请联系泽拓科技售后人员$RES\"  
    exit
  fi
  

else
  echo -e \"${RED_COLOR}安装失败,集群安装脚本不存在$RES\"  
  exit
fi

"
}












function interact_info(){



# 客户交互式输入开始
    username=$(whoami)  #运行脚本的用户
    kunlun_username='kunlun' # 默认昆仑用户
    default_sshport=22  # 默认ssh端口
    default_basedir='/home/kunlun/klustron'  # 默认安装目录
    default_version=('1.3.1' '1.2.3')





    # 主机IP
    # 调用 klustron_ip 函数并捕获返回值
    #machines_ip_list=$(klustron_ip)  
    machines_ip_str=$(klustron_ip)  
    if [ -z "$machines_ip_str" ]; then
        # 如果machines_ip_list为空，说明用户选择退出，直接退出整个脚本
        exit
    else
      IFS=' ' read -ra machines_ip_list <<< "$machines_ip_str"
    fi

    # 密码
    #echo -en "${COL_START}${YELLOW}${COL_END}"
    read -t 300 -e -s -r -p "请输入$username用户密码: " password
    echo



    
    
    # 端口
while true; do
    #echo -en "${COL_START}${YELLOW}请输入SSH端口 [默认为 $default_sshport，选择默认值请按回车]:${COL_END}"
    read -e -p "请输入SSH端口 [默认为 $default_sshport，选择默认值请按回车]: " sshport
    
    # 如果输入为空，则使用默认端口
    if [ -z "$sshport" ]; then
        sshport=$default_sshport
        break
    fi
    
    # 检查输入是否为数字
    if ! [[ "$sshport" =~ ^[0-9]+$ ]]; then
        echo -e "${RED_COLOR}错误：请输入数字。${RES}"
        #echo "错误：请输入数字。"
        continue
    fi
    
    # 检查端口范围是否合法
    if  [[ sshport -lt 1 || sshport -gt 65535 ]]; then
        echo -e "${RED_COLOR}错误：请输入介于 1 到 65535 之间的端口号。${RES}"
        #echo "错误：请输入介于 1 到 65535 之间的端口号。"
        continue
    fi
    
    break
done    




<<!
    # 用户名
while true; do
    read -e -p "请设置昆仑用户名 [默认为 $kunlun_username，选择默认值请按回车]: " kunlun_username
    
    # 如果输入为空，则使用默认用户名
    if [ -z "$kunlun_username" ]; then
        kunlun_username='kunlun'
        break
    fi
    
    # 检查输入是否包含空格
    if [[ "$kunlun_username" == *" "* ]]; then
        echo "错误：单用户名之间不能包含空格。"
        continue
    fi
    
    break
done

!







    # 安装目录
while true; do    
    #echo -en "${COL_START}${YELLOW}请输入安装目录,请使用绝对路径 [默认为 $default_basedir 选择默认值回车即可]: ${COL_END}"
    #read -p " " basedir
    read -e -p "请输入安装目录,请使用绝对路径 [默认为 $default_basedir 选择默认值回车即可]: " basedir
    #只保留最前面一个斜杆和去掉最后面所有斜杆
    basedir=$(echo "$basedir" | sed 's:^/\{2,\}:/:; s:/\+$::')
    # 如果输入为空，则使用默认路径
    if [ -z "$basedir" ]; then
    basedir=${basedir:-$default_basedir}
    break
    fi
    
	# 检查输入的路径是否是绝对路径
    if [[ "$basedir" != /* ]]; then
      echo -e "${RED_COLOR}输入的路径不是绝对路径，请重新输入${RES}"
		  #echo "输入的路径不是绝对路径，请重新输入"
		  continue
    fi
        
    # 检查输入是否包含空格
    if [[ "$basedir" == *" "* ]]; then
        echo -e "${RED_COLOR}错误：单个绝对路径不能包含空格。${RES}"
        #echo "错误：单个绝对路径不能包含空格。"
        continue
    fi    
    
    break
done   
    
    # 版本
while true; do
<<!
    echo -e "${COL_START}${YELLOW}请选择安装版本 [默认为 ${default_version[0]} 选择默认值回车即可]: 
[1]. ${default_version[0]}最新稳定版本
[2]. ${default_version[1]}之前老版本${COL_END}"

    echo -en "${COL_START}${YELLOW}请输入安装版本序号: ${COL_END}"
    read -p " " oper_id
!
    
    echo "请选择安装版本 [默认为 ${default_version[0]} 选择默认值回车即可]: 
[1]. ${default_version[0]}最新稳定版本
[2]. ${default_version[1]}历史版本"
    read -e -p "请输入安装版本序号: " oper_id
    
    
    if [[ -z "$oper_id" ]]; then
      klustron_VERSION=${klustron_VERSION:-${default_version[0]}}
      break
    else
    
      case $oper_id in
      1)
        klustron_VERSION=${default_version[0]}
        break
        ;;
      2)
        klustron_VERSION=${default_version[1]}
        break
        ;;
      *)
      echo -e "${RED_COLOR}请输入正确的序号${RES}"
     	#echo "请输入正确的序号"
  	    ;;
      esac
    fi
  done   
    
    # 将值放入数组
    control_machines=("$username" "$password" "$sshport")
    klustron_info=("$kunlun_username" "$basedir" "$klustron_VERSION")
 
<<! 
    echo "${machines_ip_list[0]}"
    echo "${machines_ip_list[1]}"
    echo "${machines_ip_list[2]}"
    echo ${control_machines[0]}
    echo ${control_machines[1]}
    echo ${control_machines[2]}
    echo ${klustron_info[0]}
    echo ${klustron_info[1]}
    echo ${klustron_info[2]}
!
# 用户交互结束 


}









# 客户交互输入基本信息,用户名,密码端口,服务器IP,数据库版本等信息
function __main() {

	# 全局变量函数
	configure_global

    # 交互式输入信息
	interact_info

    # 控制机创建昆仑用户函数
    check_kunlun_user
	
	# 函数获取昆仑用户家目非/home/user
	check_kunlun_home

    # 检查输入的主机用户名密码和ssh端口是否正确
    check_machines_sshport_passwd

    # 检查输入的主机架构是否一致
    check_arch
    
    # 检查输入的主机系统是否一致
    check_os
    
	# 检查输入的主机时区是否一致
	check_zone
	
    # 检查是否有昆仑数据库运行进程
    check_klustron_running
	
	# 下载昆仑数据库程序
    check_kunlun_setup
	
	# 创建昆仑用户秘钥  
    configure_kunlun_skey
	
	#生成配置文件
	configure_kunlun_config


	# 分发脚本
	host_initialize
	
	# 初始化环境
	execute_initialize
	
	#配置kunlun用户免密
	configure_authorized_keys

    # 下载kunlun相关组件和程序安装包	
	#kunlun_thirdparty
    #kunlun_package
	
    #生成安装脚本和安装集群环境
    install_script
    install_cluster
}







 __main





