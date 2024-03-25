#!/bin/bash


function base_env(){

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
rnu=$((RANDOM % 21))

if ! curl -s --head www.kunlunbase.com | head -n 1 | grep "200 OK" > /dev/null; then
    echo  -e "$COL_START$RED当前主机网络异常$COL_END"
    exit
fi



}





detect_system_type() {

if [[ -f "/etc/os-release" ]]; then
    source /etc/os-release
    
    if [[ "$ID" == "centos" ]]; then
        echo "CentOS"
    elif [[ "$ID" == "ubuntu" ]]; then
        echo "Ubuntu"
    elif [[ "$ID" == "kylin" ]]; then
        echo "Kylin"
    else
        echo "Unknown system"
    fi
    
else
    echo "Unknown system"
fi

}




# 检查主机操作系统类型
function system_type() {


operating_system=$(detect_system_type)

# 使用 if 语句判断函数返回值，并进行相应的操作
if [[ "$operating_system" == "Ubuntu" ]]; then
    echo "Detected Ubuntu system."
    # 在此处添加针对 Ubuntu 系统的操作
elif [[ "$operating_system" == "CentOS" ]]; then
    echo "Detected CentOS system."
    # 在此处添加针对 CentOS 系统的操作
elif [[ "$operating_system" == "Kylin" ]]; then
    echo "Detected Kylin system."
    # 在此处添加针对 Kylin 系统的操作
else
    echo "Unknown system"
    exit
fi


}




# 控制机上面设置必要的环境,否则脚本无法正确安装


function control_env(){


operating_system=$(detect_system_type)
# 使用 if 语句判断函数返回值，并进行相应的操作
if [[ "$operating_system" == "CentOS" ]]; then
    echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in figlet expect dos2unix jq nc; do
        if ! command -v "$i" &> /dev/null; then
            sudo yum install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
            fi
        fi
    done
elif [[ "$operating_system" == "Ubuntu" ]]; then
    echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in figlet expect dos2unix jq netcat; do
        if ! command -v "$i" &> /dev/null; then
            sudo apt-get install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
            fi
        fi
    done
elif [[ "$operating_system" == "Kylin" ]]; then
    echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in figlet expect dos2unix jq nc; do
        if ! command -v "$i" &> /dev/null; then
            sudo yum install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
            fi
        fi
    done
else
    echo "Unknown system"
    exit
fi





}



# 控制机上面创建kunlun用户,控制机和不在安装机器列表内

function control_kunlun(){


operating_system=$(detect_system_type)
privileges_line="${klustron_info[0]}   ALL=(ALL)       NOPASSWD: ALL"

# 使用 if 语句判断函数返回值，并进行相应的操作


if [[ "$operating_system" == "CentOS" ]]; then
  if ! id ${klustron_info[0]} &>/dev/null; then 
    sudo useradd ${klustron_info[0]} &>/dev/null && \
    if [[ $? == 0 ]]; then
        if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
            sudo sed -i "/^root/a$privileges_line" /etc/sudoers 
            if [[ $? == 0 ]]; then
                echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
            fi
        fi
    else
        echo -e "$COL_START${RED}${klustron_info[0]} User creation failed$COL_END"
        exit
    fi
  else
    if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
        sudo sed -i "/^root/a$privileges_line" /etc/sudoers  
        if [[ $? == 0 ]]; then
            echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
        fi
    else
        echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
    fi
  fi


elif [[ "$operating_system" == "Ubuntu" ]]; then
  if ! id ${klustron_info[0]} &>/dev/null; then 
    sudo useradd -r -m -s /bin/bash  $klustron_user  &>/dev/null   &&\
    if [[ $? == 0 ]]; then
        if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
            sudo sed -i "/^root/a$privileges_line" /etc/sudoers 
            if [[ $? == 0 ]]; then
                echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
            fi
        fi
    else
        echo -e "$COL_START${RED}${klustron_info[0]} User creation failed$COL_END"
        exit
    fi
  else
    if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
        sudo sed -i "/^root/a$privileges_line" /etc/sudoers  
        if [[ $? == 0 ]]; then
            echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
        fi
    else
        echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
    fi
  fi

elif [[ "$operating_system" == "Kylin" ]]; then
  if ! id ${klustron_info[0]} &>/dev/null; then 
    sudo useradd ${klustron_info[0]} &>/dev/null && \
    if [[ $? == 0 ]]; then
        if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
            sudo sed -i "/^root/a$privileges_line" /etc/sudoers 
            if [[ $? == 0 ]]; then
                echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
            fi
        fi
    else
        echo -e "$COL_START${RED}${klustron_info[0]} User creation failed$COL_END"
        exit
    fi
  else
    if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
        sudo sed -i "/^root/a$privileges_line" /etc/sudoers  
        if [[ $? == 0 ]]; then
            echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
        fi
    else
        echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END"
    fi
  fi

else
    echo "Unknown system type."
    exit
fi




}



# 控制机上面创建kunlun用户秘钥
function kunlun_secret_key(){

sudo -E su - ${klustron_info[0]} -c "
    if [[ ! -s \$HOME/.ssh/id_rsa || ! -s \$HOME/.ssh/id_rsa.pub ]]; then
        rm -f \$HOME/.ssh/id_rsa \$HOME/.ssh/id_rsa.pub \$HOME/.ssh/authorized_keys &&
        ssh-keygen -t rsa -N \"\" -f \$HOME/.ssh/id_rsa -q && \
        cat \$HOME/.ssh/id_rsa.pub > \$HOME/.ssh/authorized_keys && \
        chmod 600 \$HOME/.ssh/authorized_keys
    else
        if [[ ! -s \$HOME/.ssh/authorized_keys ]]; then
            cat \$HOME/.ssh/id_rsa.pub > \$HOME/.ssh/authorized_keys && \
            chmod 600 \$HOME/.ssh/authorized_keys
        fi
    fi

    if ! crontab -l 2>/dev/null | grep -q \"^.*${klustron_info[1]}/kunlun-node-manager-${klustron_info[2]}/data.*backup\" ; then
		  crontab -l 2>/dev/null > /tmp/crontab_tmp
      echo \"0 2 * * * find ${klustron_info[1]}/kunlun-node-manager-${klustron_info[2]}/data/ -name 'backup*' -mtime +7 | xargs rm -fr  &>/dev/null\" >> /tmp/crontab_tmp
		  crontab 2>/dev/null /tmp/crontab_tmp
		
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


#函数分发脚本,为每个机器安装klustron数据库必要环境.

function host_initialize(){

if [[ -s initialize.sh ]];then

  for i in "${machines_ip_list[@]}"
  do
    # 复制 initialize.sh到远程主机
output=$(expect <<EOF
  set timeout 3
  spawn sudo scp -rp -P${control_machines[2]} initialize.sh ${control_machines[0]}@$i:/tmp/

        expect {
                "yes/no" { send "yes\n"; exp_continue }
                "password" {
                         send -- {${control_machines[1]}}
                         send "\n"

                }


        }


        expect eof

EOF
)


  result=$(echo  "$output"|grep  'Permission denied'|wc -l)

  if [[ $result -eq 1 ]];then
    echo -e "$COL_START${RED}文件initialize.sh拷贝到${control_machines[0]}@$i失败$COL_END"
    #变量接收分发脚本失败的函数
    let count_host_initialize++
  fi

  

  done
  
  # 判断变量值如果大于等于1表示有机器分发脚本失败,为了保证每个机器安装顺利进行,脚本退出
  if [[ $count_host_initialize -ge 1 ]];then 
    exit
  else
    echo -e "$COL_START${GREEN}第三步:文件拷贝成功$COL_END"
  fi

  
  
  
else
  echo -e "$COL_START${RED}文件initialize.sh不存在$COL_END"
  exit 
fi



}



# 在安装昆仑数据库的机器上初始化环境
function execute_initialize(){

echo  -e "$COL_START${YELLOW}正在初始化机器需要一点时间,请耐心等待,请勿中断.......$COL_END" 

for i in "${machines_ip_list[@]}"
do
    # 执行initialize.sh脚本
    expect <<EOF &>/dev/null
        set timeout 300
        spawn sudo ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo bash /tmp/initialize.sh ${klustron_info[@]}"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
        }
        expect eof
EOF

done




}







function configure_Key(){


for i in "${machines_ip_list[@]}"
do
    # 复制 .ssh 文件夹到远程主机
    expect <<EOF &>/dev/null
        set timeout 300
        spawn sudo scp -rp -P${control_machines[2]} /home/${klustron_info[0]}/.ssh ${control_machines[0]}@$i:/tmp/
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
        }
        expect eof
EOF



    # 复制 .ssh 文件夹到对应的文件夹
    expect <<EOF &>/dev/null
        set timeout 300
        spawn sudo ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo cp -rp /tmp/.ssh /home/${klustron_info[0]}/ && sudo rm -fr /tmp/.ssh"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
        }
        expect eof
EOF




    # 更改 .ssh 文件夹的权限
    expect <<EOF &>/dev/null
        set timeout 300
        spawn sudo ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo chown -R ${klustron_info[0]}:${klustron_info[0]} /home/${klustron_info[0]}/.ssh"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${control_machines[1]}}
                send "\n"
            }
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
	exit
else
  echo -e "$COL_START${GREEN}第五步:昆仑用户配置免密成功$COL_END"  
fi








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

        read -p "请输入服务器IP以空格分隔 (输入 'q' 或 'Q' 退出): " ip_list
        if [[ $ip_list =~ [qQ] ]]; then
            exit
        fi

        if [ -z "$ip_list" ] || [ ! "$ip_list" ]; then
            echo -e "${COL_START}${RED}输入不能为空，请重新输入。${COL_END}"  >&2
            #echo "输入不能为空，请重新输入。"  >&2
            continue
        fi

        IFS=' ' read -ra new_ips <<< "$ip_list"
        if [ "${#new_ips[@]}" -lt 3 ]; then
            echo -e "${COL_START}${RED}输入的IP不能少于三个，请重新输入。${COL_END}"  >&2
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
            echo -e "${COL_START}${RED}以下IP地址重复输入:${COL_END}"  >&2
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
            echo -e "${COL_START}${RED}输入的IP中存在非法的IP地址，请重新输入。${COL_END}"  >&2
            echo -e "${COL_START}${RED}非法的IP地址: ${invalid_ips[@]}${COL_END}"  >&2
            
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

for i in  ${machines_ip_list[@]}
do

	    
    if ! nc -z  $i ${control_machines[2]};then 
      echo -e "$COL_START${RED}主机${i} SSH端口${sshport}有异常,无法连接,请检查网络和端口$COL_END" 
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
    echo -e "$COL_START${RED}${control_machines[0]}@${i}连接异常无法连接,请检用户名或密码$COL_END"
    #变量接收用户名或者密码不匹配机器数量
    let count_machines_passwd++
   
  fi 


done

# 判断变量值如果大于1表示有主机用户名和密码不匹配,脚本退出

if [[ $count_machines_passwd -ge 1 ]];then
  exit
fi





}


function check_klustron_running(){

for i in ${machines_ip_list[@]}; do
output=$(expect <<EOF
  set timeout 10
  spawn ssh -p${control_machines[2]} ${control_machines[0]}@${i} "ps aux | grep -w '${basedir}/kunlun-node-manager-${klustron_VERSION}' | grep -v grep|wc -l"
   
  	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { 
			 send -- {${control_machines[1]}}
			 send "\n"
		
		}
		
	
	}
 

	expect eof

EOF
)


#expect输出是以Windows格式,需要使用dos2unix工具转换
result=$(echo "$output"|dos2unix| awk 'NR==3{print $0}')

if [[ $result == 2 ]];then
  let count_klustron_exist++
  echo -e "$COL_START${RED}主机$i上已经安装有klustron数据库无法安装..........$COL_END" 
  
fi


done



# 判断变量值如果大于等于1表示有主机存在node_mgr运行进程,脚本退出
if [[ $count_klustron_exist -ge 1 ]];then 
  exit
fi


}









function klustron_config(){

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
            "ip": "$random_xpanel_ip",
            "port": 18080,
            "image": "registry.cn-hangzhou.aliyuncs.com/kunlundb/kunlun-xpanel:VERSION"
        }
EOF
)





if [[ ! -s ./klustron_config.json ]] ;then
# 生成完整的 JSON 配置文件
sudo bash -c "cat <<EOF > ./klustron_config.json
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
EOF"

fi

}










# 客户交互输入基本信息,用户名,密码端口,服务器IP,数据库版本等信息
function __main() {

# 全局变量函数
base_env

# 判断系统类型函数
#system_type

# 控制机器环境函数
control_env


    #default_username=$(whoami)
    username=$(whoami)
    default_sshport=22
    default_basedir='/home/kunlun/klustron'
    default_version=('1.3.1' '1.2.3')

<<!
    # 用户名
while true; do
    read -p "请输入用户名 [默认为 $default_username，选择默认值请按回车]: " username
    
    # 如果输入为空，则使用默认用户名
    if [ -z "$username" ]; then
        username=$default_username
        break
    fi
    
    # 检查输入是否包含空格
    if [[ "$username" == *" "* ]]; then
        echo "错误：单用户名之间不能包含空格。"
        continue
    fi
    
    break
done

!

    # 密码
    #echo -en "${COL_START}${YELLOW}${COL_END}"
    read -t 300 -s -r -p "请输入root用户密码: " password
    echo
    
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
    
    # 端口
while true; do
    #echo -en "${COL_START}${YELLOW}请输入SSH端口 [默认为 $default_sshport，选择默认值请按回车]:${COL_END}"
    read -p "请输入SSH端口 [默认为 $default_sshport，选择默认值请按回车]: " sshport
    
    # 如果输入为空，则使用默认端口
    if [ -z "$sshport" ]; then
        sshport=$default_sshport
        break
    fi
    
    # 检查输入是否为数字
    if ! [[ "$sshport" =~ ^[0-9]+$ ]]; then
        echo -e "${COL_START}${RED}错误：请输入数字。${COL_END}"
        #echo "错误：请输入数字。"
        continue
    fi
    
    # 检查端口范围是否合法
    if  [[ sshport -lt 1 || sshport -gt 65535 ]]; then
        echo -e "${COL_START}${RED}错误：请输入介于 1 到 65535 之间的端口号。${COL_END}"
        #echo "错误：请输入介于 1 到 65535 之间的端口号。"
        continue
    fi
    
    break
done    


    # 安装目录
while true; do    
    #echo -en "${COL_START}${YELLOW}请输入安装目录,请使用绝对路径 [默认为 $default_basedir 选择默认值回车即可]: ${COL_END}"
    #read -p " " basedir
    read -p "请输入安装目录,请使用绝对路径 [默认为 $default_basedir 选择默认值回车即可]: " basedir
    # 如果输入为空，则使用默认路径
    if [ -z "$basedir" ]; then
    basedir=${basedir:-$default_basedir}
    break
    fi
    
	# 检查输入的路径是否是绝对路径
    if [[ "$basedir" != /* ]]; then
      echo -e "${COL_START}${RED}输入的路径不是绝对路径，请重新输入${COL_END}"
		  #echo "输入的路径不是绝对路径，请重新输入"
		  continue
    fi
        
    # 检查输入是否包含空格
    if [[ "$basedir" == *" "* ]]; then
        echo -e "${COL_START}${RED}错误：单个绝对路径不能包含空格。${COL_END}"
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
[2]. ${default_version[1]}之前老版本"
    read -p "请输入安装版本序号: " oper_id
    
    
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
      echo -e "${COL_START}${RED}请输入正确的序号${COL_END}"
     	#echo "请输入正确的序号"
  	    ;;
      esac
    fi
  done   
    
    # 将值放入数组
    control_machines=("$username" "$password" "$sshport")
    klustron_info=("kunlun" "$basedir" "$klustron_VERSION")
    
    echo "${machines_ip_list[0]}"
    echo "${machines_ip_list[1]}"
    echo "${machines_ip_list[2]}"
    echo ${control_machines[0]}
    echo ${control_machines[1]}
    echo ${control_machines[2]}
    echo ${klustron_info[0]}
    echo ${klustron_info[1]}
    echo ${klustron_info[2]}
 

    
    # 检查输入的主机用户名密码和ssh端口是否正确
    #check_machines_sshport_passwd
    
    # 检查是否有昆仑数据库运行进程
    #check_klustron_running
    
    
    #生成配置文件
    klustron_config
    
    # 控制机创建昆仑用户函数
    control_kunlun
    
    # 创建昆仑用户秘钥
    kunlun_secret_key
    
    # 分发脚本
    host_initialize
    # 初始化环境
    execute_initialize
    
    # 配置kunlun用户免密
    configure_Key
}





 __main

