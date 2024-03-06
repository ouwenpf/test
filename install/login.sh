#!/bin/bash



klustron_ip() {
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
            echo "输入不能为空，请重新输入。"  >&2
            continue
        fi

        IFS=' ' read -ra new_ips <<< "$ip_list"
        if [ "${#new_ips[@]}" -lt 3 ]; then
            echo "输入的IP不能少于三个，请重新输入。" >&2
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
            echo "以下IP地址重复输入:"   >&2
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
            echo "输入的IP中存在非法的IP地址，请重新输入。" >&2
            echo "非法的IP地址: ${invalid_ips[@]}"   >&2
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
check_machines_sshport_passwd(){
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


check_klustron_running(){

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









klustron_config(){

# 生成 machines 节点
machines=""
for ip in "${machines_ip_list[@]}"; do
    machines+=$(cat <<EOF
        {
            "ip": "$ip",
	          "sshport": ${control_machines[2]},
            "basedir": "$basedir",
            "user": "kunlun"
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
        \"nodes\": [
            $cluster_manager_nodes
        ]
    },
    \"node_manager\": {
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
login() {
    default_username="root"
    default_sshport=22
    default_basedir='/home/kunlun/klustron'
    default_version=('1.2.3' '1.3.1')
    
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

    # 密码
    read -t 300 -s -r -p "请输入密码: " password
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
    read -p "请输入SSH端口 [默认为 $default_sshport，选择默认值请按回车]: " sshport
    
    # 如果输入为空，则使用默认端口
    if [ -z "$sshport" ]; then
        sshport=$default_sshport
        break
    fi
    
    # 检查输入是否为数字
    if ! [[ "$sshport" =~ ^[0-9]+$ ]]; then
        echo "错误：请输入数字。"
        continue
    fi
    
    # 检查端口范围是否合法
    if  [[ sshport -lt 1 || sshport -gt 65535 ]]; then
        echo "错误：请输入介于 1 到 65535 之间的端口号。"
        continue
    fi
    
    break
done    


    # 安装目录
while true; do    
    read -p "请输入安装目录,请使用绝对路径 [默认为 $default_basedir 选择默认值回车即可]: " basedir
    # 如果输入为空，则使用默认路径
    if [ -z "$basedir" ]; then
    basedir=${basedir:-$default_basedir}
    break
    fi
    
	# 检查输入的路径是否是绝对路径
    if [[ "$basedir" != /* ]]; then
		  echo "输入的路径不是绝对路径，请重新输入"
		  continue
    fi
        
    # 检查输入是否包含空格
    if [[ "$basedir" == *" "* ]]; then
        echo "错误：单个绝对路径不能包含空格。"
        continue
    fi    
    
    break
done   
    
    # 版本
while true; do
    echo "请选择安装版本 [默认为 ${default_version[0]} 选择默认值回车即可]: 
[1]. ${default_version[0]}稳定版本
[2]. ${default_version[1]}最新版本"
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
     	echo "请输入正确的序号"
  	    ;;
      esac
    fi
  done   
    
    # 将值放入数组
    control_machines=("$username" "$password" "$sshport")
    
    echo "${machines_ip_list[@]}"
    echo "${machines_ip_list[1]}"
    echo "${machines_ip_list[2]}"
    echo ${control_machines[*]}
    echo $basedir
    echo $klustron_VERSION

    
    # 检查输入的主机用户名密码和ssh端口是否正确
    #check_machines_sshport_passwd
    
    # 检查是否有昆仑数据库运行进程
    #check_klustron_running
    
    
    #生成配置文件
    klustron_config
}





login
