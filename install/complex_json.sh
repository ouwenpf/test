#!/bin/bash


declare -A system_oss
declare -A system_archs
declare -A system_timezones

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
YELLOW_COLOR_UF='\e[5;33m'   # 黄色字体闪烁
RED_COLOR_UF='\e[4;5;31m'   # 红色下划线字体闪烁

# 系统必须的命令
for i in  expect dos2unix jq nc; do
   if ! command -v "$i" &> /dev/null; then
		missing_commands+=("$i")
   fi
done

if [[ ${#missing_commands[@]} -gt 0 ]]; then
    echo -e "${GREEN_COLOR}========================================================$RES"
    echo -e "$RED_COLOR_UF错误:$RES"
    echo -e "$YELLOW_COLOR请先手工安装好以下命令："
	echo -e "$YELLOW_COLOR${missing_commands[*]}$RES"
    echo -e "${GREEN_COLOR}========================================================$RES"
    exit 1
fi

if [[ ${#missing_commands[@]} -gt 0 ]]; then
    echo -e "${GREEN_COLOR}========================================================$RES"
    echo -e "$RED_COLOR_UF错误:$RES"
    echo -e "$YELLOW_COLOR请先手工安装好以下命令："
	echo -e "$YELLOW_COLOR${missing_commands[*]}$RES"
    echo -e "${GREEN_COLOR}========================================================$RES"
    exit 1
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
	    # 统一颜色
        UniColor=$(echo -en "${GREEN_COLOR}请输入服务器IP以空格分隔 (输入 'q' 或 'Q' 退出): ${RES}")
        read -e -p "$UniColor" ip_list
        if [[ $ip_list =~ [qQ] ]]; then
            exit
        fi

        if [ -z "$ip_list" ] || [ ! "$ip_list" ]; then
            echo -e "${RED_COLOR}IP输入不能为空,请重新输入${RES}"  >&2
            #echo "输入不能为空，请重新输入。"  >&2
            continue
        fi

        IFS=' ' read -e -ra new_ips <<< "$ip_list"
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
            
            #echo "输入的IP中存在非法的IP地址,请重新输入" >&2
            #echo "非法的IP地址: ${invalid_ips[@]}"   >&2
     			  new_ips=()
			      seen=()
            continue
        fi

        if [ "${#new_ips[@]}" -lt 3 ]; then
            echo -e "${RED_COLOR}输入的IP不能少于三个，请重新输入。${RES}"  >&2
            #echo "输入的IP不能少于三个,请重新输入" >&2
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
      echo  -e "${GREEN_COLOR}========================================================$RES"
      echo -en "$RED_COLOR_UF错误:$RES"
	  echo -en "$YELLOW_COLOR
主机${i}的SSH端口${sshport}出现异常,无法连接
请检查IP,网络和端口
$RES"

      #变量接收不通的机器数量
      let count_host_sshport++
      continue  
    fi
     
done


#判断变量是否大于等于1,成立表示有机器ssh端口不通,脚本退出
if [[ $count_host_sshport -ge 1 ]];then
  echo  -e "${GREEN_COLOR}========================================================$RES"
  exit
fi






#检查用户名和密码是否正确
for i in  ${machines_ip_list[@]}
do

    
         
# 探测用户名和密码是否正确         
  expect <<EOF  >/dev/null 2>&1
  set timeout 3
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
    echo  -e "${GREEN_COLOR}========================================================$RES"
    echo -en "$RED_COLOR_UF错误:$RES"
    echo -en "$YELLOW_COLOR
${control_machines[0]}@${i}输入密码有误
$RES"

    #变量接收用户名或者密码不匹配机器数量
    let count_machines_passwd++
   
  fi 


done

# 判断变量值如果大于1表示有主机用户名和密码不匹配,脚本退出

if [[ $count_machines_passwd -ge 1 ]];then
  echo  -e "${GREEN_COLOR}========================================================$RES"
  exit
fi





}








#函数检查机器的架构是否一致
function check_arch(){

for i in "${machines_ip_list[@]}"
do

   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "arch"
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


system_archs["$i"]=$(printf "%s" "$output"|sed '1d'|egrep -v 'password'|tr -d '\r')
first_arch=${system_archs[${machines_ip_list[0]}]}

if [[ "${system_archs["$i"]}" != "$first_arch" ]]; then
   let  count_arch++
fi


done


#判断变量是否大于等于1,成立表示有机器架构不一样,脚本退出

if [[ $count_arch -ge 1 ]];then
	
    echo  -e "${GREEN_COLOR}========================================================$RES"
    echo -e "$RED_COLOR_UF错误主机架构不一致:$RES"
    for i in "${machines_ip_list[@]}"
    do

		echo -e "$YELLOW_COLOR主机${i}架构为:${system_archs["$i"]}$RES"

    done

   echo  -e "${GREEN_COLOR}========================================================$RES"
   exit
fi



}



#函数检查机器的OS是否一致
function check_os(){


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



system_oss["$i"]=$(printf "%s" "$output"|sed '1d'|egrep -v 'password'|egrep  -iw 'ID'|sed 's/ID=//; s/"//g'|tr -d '\r')
first_os=${system_oss[${machines_ip_list[0]}]}


if [[ "${system_oss["$i"]}" != "$first_os" ]]; then
   let  count_os++
fi


done


#判断变量是否大于等于1,成立表示有机器系统不一致,脚本退出
if [[ $count_os -ge 1 ]];then

    echo  -e "${GREEN_COLOR}========================================================$RES"
    echo -e "$RED_COLOR_UF错误主机系统不一致:$RES"
    for i in "${machines_ip_list[@]}"
    do

		echo -e "$YELLOW_COLOR主机${i}系统为:${system_oss["$i"]}$RES"

    done

   echo  -e "${GREEN_COLOR}========================================================$RES"
   exit

fi



}



#函数检查机器的时区是否一致

function check_zone(){


for i in "${machines_ip_list[@]}"
do
    # 执行initialize.sh脚本
   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "timedatectl | grep 'Time zone' |awk -F ':' '{print $2}'|awk '{print $1}'"
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


system_timezones["$i"]=$(printf "%s" "$output"|egrep -v 'password'|awk 'NR==2'|awk -F 'zone:' '{print $2}'|awk -F '[ ]+'  '{print $2}')

first_timezone=${system_timezones[${machines_ip_list[0]}]}

if [[ "${system_timezones["$i"]}" != "$first_timezone" ]]; then
   let  count_timezone++
fi


done


#判断变量是否大于等于1,成立表示有机器ssh端口不通,脚本退出
if [[ $count_timezone -ge 1 ]];then

    echo  -e "${GREEN_COLOR}========================================================$RES"
    echo -e "$RED_COLOR_UF错误主机时区不一致:$RES"
    for i in "${machines_ip_list[@]}"
    do

                echo -e "$YELLOW_COLOR主机${i}时区为:${system_timezones["$i"]}$RES"

    done

   echo  -e "${GREEN_COLOR}========================================================$RES"
   exit

fi

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
            "basedir": "${klustron_info[1]}",
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
                "brpc_http_port": 58100,
                "brpc_raft_port": 58101,
                "prometheus_port_start": 59110
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
                "brpc_http_port": 58102,
                "tcp_port": 58103,
                "prometheus_port_start": 58110,
                "storage_portrange": "57000-58000",
                "server_portrange": "47000-48000"
    },
EOF
)
done
node_manager_nodes="${node_manager_nodes%,}"  # 移除最后一个对象后面的逗号



# 随机选择一个IP作为xpanel的ip,如果需要多个xpanle地址请修改如:-lt 2即可
xpanel_ips=()
while [ ${#xpanel_ips[@]} -lt 1 ]; do
    random_index=$((RANDOM % ${#machines_ip_list[@]}))
    ip="${machines_ip_list[$random_index]}"
    if [[ ! " ${xpanel_ips[@]} " =~ " ${ip} " ]]; then
        xpanel_ips+=("$ip")
    fi
done



# 生成 xpanel 节点

# 控制xpanle数量
xpanel_ips=()
while [ ${#xpanel_ips[@]} -lt 3 ]; do
    random_index=$((RANDOM % ${#machines_ip_list[@]}))
    ip="${machines_ip_list[$random_index]}"
    if [[ ! " ${xpanel_ips[@]} " =~ " ${ip} " ]]; then
        xpanel_ips+=("$ip")
    fi
done



xpanel=""
for ip in "${xpanel_ips[@]}"; do
    xpanel+=$(cat <<EOF

    {
                "ip": "$ip",
                "port": ${default_xpanel_port}

    },
EOF
)
done
xpanel="${xpanel%,}"   # 移除最后一个对象后面的逗号






sudo -E su - ${control_machines[0]} -c "

cat <<EOF > \"$config_name\"
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
    \"xpanel\": {
        \"upgrade_all\": false,
        \"imageType\": \"file\",
        \"nodes\": [
            $xpanel
        ]
    }
}
EOF

"
}




function auto_install_config() {
    ENC_passwd=$(echo ${control_machines[1]}|openssl base64)
	# 开始构建 JSON 字符串
	json="{"
	json+="\"time\": \"$(date '+%F %T')\","
	json+="\"version\": \"${klustron_info[2]}\","
	json+="\"machines\": ["
	
	
	# 循环遍历 IP 列表并添加到 JSON 中
	for ((i=0; i<${#machines_ip_list[@]}; i++)); do
		json+="{\"ip\": \"${machines_ip_list[$i]}\","
		json+="\"password\": \"$ENC_passwd\","
		json+="\"user\": \"${control_machines[0]}\","
		json+="\"sshport\": ${control_machines[2]},"
		json+="\"os\": \"${system_oss[${machines_ip_list[$i]}]}\","
		json+="\"arch\": \"${system_archs[${machines_ip_list[$i]}]}\""
		if [ $i -ne $((${#machines_ip_list[@]}-1)) ]; then
			json+="},"
		else
			json+="}"
		fi
	done
	
	json+="],"
	
	# 添加 klustron 字段
	json+="\"klustron\": ["
	for ((i=0; i<${#machines_ip_list[@]}; i++)); do
		#json+="{\"ip\": \"${machines_ip_list[$i]}\","
		json+="{\"user\": \"${klustron_info[0]}\","
		json+="\"password\": \"${kunlun_password}\","
		json+="\"basedir\": \"${klustron_info[1]}\"}"
		if [ $i -ne $((${#machines_ip_list[@]}-1)) ]; then
			json+=","
		fi
	done
	json+="],"
	
	# 添加 xpanel 字段
	json+="\"xpanel\": ["
	for ((i=0; i<${#xpanel_ips[@]}; i++)); do
		json+="{\"ip\": \"${xpanel_ips[$i]}\", \"port\": $default_xpanel_port, \"url\": \"http://${xpanel_ips[$i]}:$default_xpanel_port/KunlunXPanel/\"}"
		if [ $i -ne $((${#xpanel_ips[@]}-1)) ]; then
			json+=","
		fi
	done
	json+="]"
	
	json+="}"


    # 将 JSON 字符串写入文件
    echo "$json" | jq '.' > auto_install.json
}



function interact_info(){



# 客户交互式输入开始
    username=$(whoami)  #运行脚本的用户
    kunlun_username='kunlun' # 默认昆仑用户
    default_sshport=22  # 默认ssh端口
	default_xpanel_port=18080 # 默认xpanel端口
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
    echo -en "${GREEN_COLOR}请输入$username用户密码: ${RES}"
	read -t 300 -e -s -r  password
    #read -t 300 -e -s -r -p "请输入$username用户密码: " password
    echo



    
    
    # 端口
while true; do
    echo -en "${GREEN_COLOR}请输入SSH端口 [默认为 $default_sshport，选择默认值请按回车]: ${RES}"
	read -e -p " " sshport
    #read -e -p "请输入SSH端口 [默认为 $default_sshport，选择默认值请按回车]: " sshport
    
    # 如果输入为空，则使用默认端口
    if [ -z "$sshport" ]; then
        sshport=$default_sshport
        break
    fi
    
    # 检查输入是否为数字
    if ! [[ "$sshport" =~ ^[0-9]+$ ]]; then
        echo -e "${RED_COLOR}错误：请输入数字${RES}"
        #echo "错误：请输入数字。"
        continue
    fi
    
    # 检查端口范围是否合法
    if  [[ sshport -lt 1 || sshport -gt 65535 ]]; then
        echo -e "${RED_COLOR}错误：请输入介于 1 到 65535 之间的端口号${RES}"
        #echo "错误：请输入介于 1 到 65535 之间的端口号。"
        continue
    fi
    
    break
done    




<<!
    # 用户名
while true; do
    echo -en "${GREEN_COLOR}请设置昆仑用户名 [默认为 $kunlun_username，选择默认值请按回车]: ${RES}"
	read -e -p "" kunlun_username
    #read -e -p "请设置昆仑用户名 [默认为 $kunlun_username，选择默认值请按回车]: " kunlun_username
    
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
    echo -en "${GREEN_COLOR}请输入安装目录,请使用绝对路径 [默认为 $default_basedir选择默认值回车即可]: ${RES}"
    read -e -p " " basedir
    #read -e -p "请输入安装目录,请使用绝对路径 [默认为 $default_basedir 选择默认值回车即可]: " basedir
    #过滤成正常的路径格式
    #basedir=$(echo "$basedir" | sed 's:^/\{2,\}:/:; s:/\+$::')
	basedir=$(echo "$basedir" | sed 's:\/\{2,\}:/:g; s:/$::')
	
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
    
    
echo -en "${GREEN_COLOR}请选择安装版本 [默认为 ${default_version[0]} 选择默认值回车即可]:
${RED_COLOR}[1].${RES} ${YELLOW_COLOR_UF}${default_version[0]}最新稳定版本${RES}
${RED_COLOR}[2].${RES} ${YELLOW_COLOR}${default_version[1]}经典版本${RES}
${RES}"

    echo -en "${GREEN_COLOR}请输入安装版本序号: ${RES}"
    read -e -p "" oper_id
    #read -e -p "请输入安装版本序号: " oper_id
    
    
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
	readonly kunlun_password="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()' | fold -w 16 | head -n 1|openssl base64)"
	

 
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







function __main() {
	# 全局变量函数
	configure_global

    # 交互式输入信息
	interact_info
	
	# 检查输入的主机用户名密码和ssh端口是否正确
    check_machines_sshport_passwd

	#生成配置文件
	configure_kunlun_config
	
    # 检查输入的主机架构是否一致
    check_arch
    
    # 检查输入的主机系统是否一致
    check_os
    
	# 检查输入的主机时区是否一致
	check_zone
	
    #生成配置文件

	auto_install_config

}

__main
