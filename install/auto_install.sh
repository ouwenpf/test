 
#!/bin/bash

declare -A current_users
declare -A kunlun_users
declare -A sshports
declare -A xpanel_ports
declare -A basedirs
declare -A system_oss
declare -A system_archs
declare -A system_timezones
declare -A passwords


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

rnu=$((RANDOM % 21))


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




}







function klustron_ip() {
    declare -a machines_ip_list=()
    declare -A seen
    auto_config="$1"
    validate_ip() {
        local ip=$1
        local regex="^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$"

        if ! [[ $ip =~ $regex ]]; then
            return 1
        fi
    }


		ip_list=($(jq -r '.machines[].ip' $auto_config))

        if [ -z "$ip_list" ] || [ ! "$ip_list" ]; then
            echo -e "${RED_COLOR}配置文件$auto_config中machines标签IP为空,请重新设置${RES}"  >&2
            #echo "输入不能为空，请重新输入。"  >&2
			exit 1
            
        fi

		new_ips=("${ip_list[@]}")

        if [ "${#new_ips[@]}" -lt 3 ]; then
            echo -e "${RED_COLOR}配置文件$auto_config中machines标签IP不能少于三个，请重新设置${RES}"  >&2
            #echo "输入的IP不能少于三个，请重新输入。" >&2
			exit 1
 
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
 

			if [ "$duplicate_found" = true ]; then
				echo -e "${RED_COLOR}配置文件$auto_config中machines标签以下IP地址重复:${RES}"  >&2
				#echo "以下IP地址重复,请重新设置:"   >&2
				printf '%s\n' "${duplicate_ips[@]}"   >&2
					new_ips=()
			        seen=()
				exit 1
  
			fi
		
        done 
        # 判断每个IP的合法性
        local invalid_ips=()
        for ip in "${new_ips[@]}"; do
            if ! validate_ip "$ip"; then
                invalid_ips+=("$ip")
            fi
        done

        if [ "${#invalid_ips[@]}" -gt 0 ]; then
            echo -e "${RED_COLOR}配置文件$auto_config中machines标签存在非法的IP地址，请重新设置${RES}"  >&2
            echo -e "${RED_COLOR}非法的IP地址: ${invalid_ips[@]}${RES}"  >&2
            
            #echo "输入的IP中存在非法的IP地址，请重新设置" >&2
            #echo "非法的IP地址: ${invalid_ips[@]}"   >&2
     			  new_ips=()
			      seen=()
			exit 1
            
        fi

        # 如果通过所有检查，将IP添加到数组中
        machines_ip_list=("${new_ips[@]}")

        
    

    # 将IP列表作为返回值返回
    echo "${machines_ip_list[@]}"
}





function klustron_xpanel_ip() {
    declare -a xpanel_ip_list=()
    declare -A seen
    auto_config="$1"
    validate_ip() {
        local ip=$1
        local regex="^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$"

        if ! [[ $ip =~ $regex ]]; then
            return 1
        fi
    }


		ip_list=($(jq -r '.xpanel[].ip' $auto_config))

        if [ -z "$ip_list" ] || [ ! "$ip_list" ]; then
            echo -e "${RED_COLOR}配置文件$auto_config中xpanel标签IP为空,请重新设置${RES}"  >&2
            #echo "输入不能为空，请重新输入。"  >&2
			exit 1
            
        fi

		new_ips=("${ip_list[@]}")

        if [ "${#new_ips[@]}" -lt 1 ]; then
            echo -e "${RED_COLOR}配置文件$auto_config中xpanel标签IP不能少于一个，请重新设置${RES}"  >&2
            #echo "输入的IP不能少于三个，请重新输入。" >&2
			exit 1
 
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
 

			if [ "$duplicate_found" = true ]; then
				echo -e "${RED_COLOR}配置文件$auto_config中xpanel标签以下IP地址重复:${RES}"  >&2
				#echo "以下IP地址重复,请重新设置:"   >&2
				printf '%s\n' "${duplicate_ips[@]}"   >&2
					new_ips=()
			        seen=()
				exit 1
  
			fi
		
        done 
        # 判断每个IP的合法性
        local invalid_ips=()
        for ip in "${new_ips[@]}"; do
            if ! validate_ip "$ip"; then
                invalid_ips+=("$ip")
            fi
        done

        if [ "${#invalid_ips[@]}" -gt 0 ]; then
            echo -e "${RED_COLOR}配置文件$auto_config中xpanel标签存在非法的IP地址，请重新设置${RES}"  >&2
            echo -e "${RED_COLOR}非法的IP地址: ${invalid_ips[@]}${RES}"  >&2
            
            #echo "输入的IP中存在非法的IP地址，请重新设置" >&2
            #echo "非法的IP地址: ${invalid_ips[@]}"   >&2
     			  new_ips=()
			      seen=()
			exit 1
            
        fi

        # 如果通过所有检查，将IP添加到数组中
        xpanel_ip_list=("${new_ips[@]}")

        
    

    # 将IP列表作为返回值返回
    echo "${xpanel_ip_list[@]}"
}





function interact_info() {

 # 读取用户名、密码、SSH端口、基础目录和版本号
	auto_config="$1"
	default_current_user=$(whoami)  # 运行脚本的用户
    default_kunlun_user="kunlun"    # 默认昆仑用户
    default_password=""       
    default_sshport=22        # 默认ssh端口
	default_xpanel_port=18080 # 默认xpanel端口
    default_basedir="/home/kunlun/klustron"
    default_klustron_VERSION="1.3.1"

# 分发机上创建用户用于安装昆仑数据库
	klustron_info=("$default_kunlun_user" "$(echo 'JyEiIyQlJlwnKCkqKywtLi86Ozw9Pj9AW1xcXV5fYHt8fX4gJwo='|openssl   base64 -d)" "$default_klustron_VERSION")

    # 检查运行当前脚本的用户
    if [ -z "${default_current_user}" ]; then
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "$YELLOW_COLOR无法获取当前用户名$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
        exit 1
    fi	
	

	
	
    # 检查配置文件是否符合json语法
    if [ ! -s "$auto_config" ]; then
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "$YELLOW_COLOR找不到$auto_config文件$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
        exit 1
    else
	if ! jq '.' $auto_config &>/dev/null;then 
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "$YELLOW_COLOR$auto_config文件不符合json语法$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
        exit 1
	fi
    fi

    #从config.json文件中读取变量并存入数组,检查ip合法性规则校验   
    machines_ip_str=$(klustron_ip "$1")  
    if [ -z "$machines_ip_str" ]; then
        #如果machines_ip_list为空，说明用户选择退出，直接退出整个脚本
        exit
    else
      IFS=' ' read -ra machines_ip_list <<< "$machines_ip_str"
    fi

	#从config.json文件中读取变量并存入数组,考虑xpanel不在ip列表内,检查ip合法性规则校验
    xpanel_ip_str=$(klustron_xpanel_ip "$1")  
    if [ -z "$xpanel_ip_str" ]; then
        #如果xpanel_ip_list为空，说明用户选择退出，直接退出整个脚本
        exit
    else
      IFS=' ' read -ra xpanel_ip_list <<< "$xpanel_ip_str"
    fi

    


    # 验证当前执行脚本用户名和验证合法性
    readarray  -t  current_user <<< "$(jq -r '.machines[].user' $auto_config|sed 's/^[ \t]*//;s/[ \t]*$//')"

		# 循环遍历数组，并替换为空和 null 的元素为默认值，并验用户名的合法性
		for ((i = 0; i < ${#current_user[@]}; i++)); do
			# 如果元素为空或为 null，则替换为默认值
			if [[ -z "${current_user[$i]}" || "${current_user[$i],,}" == "null" ]]; then
				current_user[$i]=$default_current_user
			fi
		
	
		if [[ "${current_user[$i]}" == *" "* ]]; then
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "${YELLOW_COLOR}用户名之间不能包含空格,请重新配置$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
		exit 1  
		fi	
		
	done


## 用户名

    #验证昆仑用户名和验证合法性
	readarray  -t  kunlun_user <<< "$(jq -r '.machines[].kunlun_user' $auto_config|sed 's/^[ \t]*//;s/[ \t]*$//')"
		# 循环遍历数组，并替换为空和 null 的元素为默认值，并验用户名的合法性
	for ((i = 0; i < ${#kunlun_user[@]}; i++)); do
		# 如果元素为空或为 null，则替换为默认值
		if [[ -z "${kunlun_user[$i]}" || "${kunlun_user[$i],,}" == "null" ]]; then
			kunlun_user[$i]=$default_kunlun_user
		fi
		
	
    if [[ "${kunlun_user[$i]}" == "root" ]]; then
	  echo  -e "${GREEN_COLOR}========================================================$RES"
	  echo  -e "$RED_COLOR_UF错误:$RES"
	  echo  -e "${YELLOW_COLOR}昆仑用户不能使用root用户,请重新配置$RES"
	  echo  -e "${GREEN_COLOR}========================================================$RES"
	  exit 1  
    fi

    if [[ "${kunlun_user[$i]}" == *" "* ]]; then
	  echo  -e "${GREEN_COLOR}========================================================$RES"
	  echo  -e "$RED_COLOR_UF错误:$RES"
	  echo  -e "${YELLOW_COLOR}昆仑用户名之间不能包含空格,请重新配置$RES"
	  echo  -e "${GREEN_COLOR}========================================================$RES"
	  exit 1  
    fi
	done
	


## 端口

	 # 检查sshport端口的合法性
	   readarray  -t  sshport <<< "$(jq -r '.machines[].sshport' $auto_config|sed 's/^[ \t]*//;s/[ \t]*$//')"
	   # 循环遍历数组，并替换为空和 null 的元素为默认值，并验证端口合法性
	   for ((i = 0; i < ${#sshport[@]}; i++)); do
	   	# 如果元素为空或为 null，则替换为默认端口值
	   	if [[ -z "${sshport[$i]}" || "${sshport[$i],,}" == "null" ]]; then
	   		sshport[$i]=$default_sshport
	   	fi
	   
	   	# 验证端口是否为数字
	   	if ! [[ "${sshport[$i]}" =~ ^[0-9]+$ ]]; then
			echo  -e "${GREEN_COLOR}========================================================$RES"
			echo  -e "$RED_COLOR_UF错误:$RES"
			echo  -e "${YELLOW_COLOR}sshport端口必须为数字$RES"
			echo  -e "${GREEN_COLOR}========================================================$RES"
			exit 1  
	   	fi
	   	
	   	# 检查端口范围是否合法
	   	if [[ "${sshport[$i]}" -lt 1 || "${sshport[$i]}" -gt 65535 ]]; then
			echo  -e "${GREEN_COLOR}========================================================$RES"
			echo  -e "$RED_COLOR_UF错误:$RES"
			echo  -e "${YELLOW_COLOR}端口范围1到65535之间,请重新配置$RES"
			echo  -e "${GREEN_COLOR}========================================================$RES"
			exit 1
	   	fi
	   done
	   

	 # 检查xpanle端口的合法性
	   readarray  -t  xpanel_port <<< "$(jq -r '.xpanel[].port' $auto_config|sed 's/^[ \t]*//;s/[ \t]*$//')"
	   # 循环遍历数组，并替换为空和 null 的元素为默认值，并验证端口合法性
	   for ((i = 0; i < ${#xpanel_port[@]}; i++)); do
	   	# 如果元素为空或为 null，则替换为默认端口值
	   	if [[ -z "${xpanel_port[$i]}" || "${xpanel_port[$i],,}" == "null" ]]; then
	   		xpanel_port[$i]=$default_xpanel_port
	   	fi
	   
	   	# 验证端口是否为数字
	   	if ! [[ "${xpanel_port[$i]}" =~ ^[0-9]+$ ]]; then
			echo  -e "${GREEN_COLOR}========================================================$RES"
			echo  -e "$RED_COLOR_UF错误:$RES"
			echo  -e "${YELLOW_COLOR}xpanle端口必须为数字$RES"
			echo  -e "${GREEN_COLOR}========================================================$RES"
			exit 1  
	   	fi
	   	
	   	# 检查端口范围是否合法
	   	if [[ "${xpanel_port[$i]}" -lt 1 || "${xpanel_port[$i]}" -gt 65535 ]]; then
			echo  -e "${GREEN_COLOR}========================================================$RES"
			echo  -e "$RED_COLOR_UF错误:$RES"
			echo  -e "${YELLOW_COLOR}端口范围1到65535之间,请重新配置$RES"
			echo  -e "${GREEN_COLOR}========================================================$RES"
			exit 1
	   	fi
	   done
	  
	  
	  
## 安装路径	  
   # 获取basedir路径 
	readarray  -t  basedir <<< "$(jq -r '.machines[].basedir' $auto_config| sed 's:\/\{2,\}:/:g; s:/$::'|sed 's/^[ \t]*//;s/[ \t]*$//')"
		# 循环遍历数组，并替换为空和 null 的元素为默认值，并验证路径合法性
		for ((i = 0; i < ${#basedir[@]}; i++)); do
			# 如果元素为空或为 null，则替换为默认值
			if [[ -z "${basedir[$i]}" || "${basedir[$i],,}" == "null" ]]; then
				basedir[$i]=$default_basedir
			fi
	
	
		# 检查输入的路径是否是绝对路径
	if [[ "${basedir[$i]}" != /* ]]; then
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "${YELLOW_COLOR}安装路径不是绝对路径，请重新配置$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
		exit 1 
	fi
		
	# 检查输入是否包含空格
	if [[ "${basedir[$i]}" == *" "* ]]; then
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "${YELLOW_COLOR}单个绝对路径不能包含空格$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
		exit 1  
	fi    
	
	done
	

## 系统版本

   # 获取系统操作
	readarray  -t  system_os <<< "$(jq -r '.machines[].os' $auto_config| sed 's:\/\{2,\}:/:g; s:/$::'|sed 's/^[ \t]*//;s/[ \t]*$//')"
		# 循环遍历数组，并替换为空和 null 的元素为默认值，并验证系统版本合法性
		for ((i = 0; i < ${#system_os[@]}; i++)); do
			# 如果元素为空或为 null，则退出
			if [[ -z "${system_os[$i]}" || "${system_os[$i],,}" == "null" ]]; then
				echo  -e "${GREEN_COLOR}========================================================$RES"
				echo  -e "$RED_COLOR_UF错误:$RES"
				echo  -e "${YELLOW_COLOR}无法获取系统版本$RES"
				echo  -e "${GREEN_COLOR}========================================================$RES"
				exit 1 
			fi
	
		
	# 检查输入是否包含空格
	if [[ "${system_os[$i]}" == *" "* ]]; then
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "${YELLOW_COLOR}Unknown system$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
		exit 1  
	fi    
	
	done


## CPU架构

   # 获取系统架构
	readarray  -t  system_arch <<< "$(jq -r '.machines[].arch' $auto_config| sed 's:\/\{2,\}:/:g; s:/$::'|sed 's/^[ \t]*//;s/[ \t]*$//')"
		# 循环遍历数组，并替换为空和 null 的元素为默认值，并验证架构合法性
		for ((i = 0; i < ${#system_arch[@]}; i++)); do
			# 如果元素为空或为 null，则退出
			if [[ -z "${system_arch[$i]}" || "${system_arch[$i],,}" == "null" ]]; then
				echo  -e "${GREEN_COLOR}========================================================$RES"
				echo  -e "$RED_COLOR_UF错误:$RES"
				echo  -e "${YELLOW_COLOR}无法获取系统架构$RES"
				echo  -e "${GREEN_COLOR}========================================================$RES"
				exit 1 
			fi
	
		
	# 检查输入是否包含空格
	if [[ "${system_arch[$i]}" == *" "* ]]; then
		echo  -e "${GREEN_COLOR}========================================================$RES"
		echo  -e "$RED_COLOR_UF错误:$RES"
		echo  -e "${YELLOW_COLOR}Unknown system_arch$RES"
		echo  -e "${GREEN_COLOR}========================================================$RES"
		exit 1  
	fi    
	
	done
	
	
	
## root密码

	 # 检查sshport端口的合法性
	   readarray  -t  password <<< "$(jq -r '.machines[].password' $auto_config)"
	   # 循环遍历数组，并替换为空和 null 的元素为默认值
	   for ((i = 0; i < ${#password[@]}; i++)); do
	   	# 如果元素为空或为 null，则替换为默认值
	   	if [[ -z "${password[$i]}" || "${password[$i],,}" == "null" ]]; then
	   		password[$i]=$default_password
		else	
			password[$i]=$(echo "${password[$i]}" | openssl base64 -d)
	   	fi
	    
		
		done
		
		
		
		
		
#初始化数据



for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    current_users[${machines_ip_list[i]}]=${current_user[i]}
done    



for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    kunlun_users[${machines_ip_list[i]}]=${kunlun_user[i]}
done    


for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    sshports[${machines_ip_list[i]}]=${sshport[i]}
done    



for ((i=0; i<${#xpanel_ip_list[@]}; i++))
do
    xpanel_ports[${xpanel_ip_list[i]}]=${xpanel_port[i]}
done    




for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    basedirs[${machines_ip_list[i]}]=${basedir[i]}
done    





for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    system_oss[${machines_ip_list[i]}]=${system_os[i]}
done    





for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    system_archs[${machines_ip_list[i]}]=${system_arch[i]}
done    




for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    passwords[${machines_ip_list[i]}]=${password[i]}
done    




}




function configure_kunlun_config(){

config_name="klustron_config.json"

# 生成 machines 节点
machines=""
for ip in "${machines_ip_list[@]}"; do
    machines+=$(cat <<EOF
    
    {
            "ip": "$ip",
            "sshport": ${sshports[$ip]},
            "basedir": "${basedirs[$ip]}",
            "user": "${kunlun_users[$ip]}"
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





xpanel=""
for ip in "${xpanel_ip_list[@]}"; do
    xpanel+=$(cat <<EOF

    {
                "ip": "$ip",
                "port": ${xpanel_ports[$ip]}

    },
EOF
)
done
xpanel="${xpanel%,}"   # 移除最后一个对象后面的逗号




sudo -E su - root -c "



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




#函数检查机器ssh端口和root密码是否正确
function check_machines_sshport_passwd(){
# 检查ssh端口是否通
count_host_sshport=0
count_machines_passwd=0


echo  -e "$YELLOW_COLOR正在检查系统环境.....$RES"
for i in  ${machines_ip_list[@]}
do

	    
    if ! nc -w 3 -z  $i ${sshports[$i]};then 
      echo  -e "${GREEN_COLOR}========================================================$RES"
      echo -en "$RED_COLOR_UF错误:$RES"
	  echo -en "$YELLOW_COLOR
主机${i}的SSH端口${sshports[$i]}出现异常,无法连接
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
  spawn ssh -p${sshports[$i]} ${current_users[$i]}@${i} "echo Password is correct" 
  expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" {
        send -- {${passwords[$i]}}
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
${current_users[$i]}@${i}输入密码有误
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



#函数检查机器的OS是否一致
function check_os(){



for i in "${machines_ip_list[@]}"
do

   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh   -p${sshports[$i]} ${current_users[$i]}@$i 2>/dev/null  "cat /etc/os-release |egrep  -iw 'ID'"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${passwords[$i]}}
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



#函数检查机器的架构是否一致
function check_arch(){


for i in "${machines_ip_list[@]}"
do

   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh  -p${sshports[$i]} ${current_users[$i]}@$i "arch"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${passwords[$i]}}
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








#函数检查机器的时区是否一致

function check_zone(){

for i in "${machines_ip_list[@]}"
do
    # 执行initialize.sh脚本
   output=$(expect <<EOF #&>/dev/null
        set timeout 3
        spawn  ssh  -p${sshports[$i]} ${current_users[$i]}@$i "sudo timedatectl | grep 'Time zone' |awk -F ':' '{print $2}'|awk '{print $1}'"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- {${passwords[$i]}}
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




function print_array(){

for ((i=0; i<${#machines_ip_list[@]}; i++))
do
    echo "current_users[${machines_ip_list[i]}]:${current_users[${machines_ip_list[i]}]}"
	echo "kunlun_users[${machines_ip_list[i]}]:${kunlun_users[${machines_ip_list[i]}]}"
	echo "sshports[${machines_ip_list[i]}]:${sshports[${machines_ip_list[i]}]}"
	echo "basedirs[${machines_ip_list[i]}]:${basedirs[${machines_ip_list[i]}]}"
	echo "system_oss[${machines_ip_list[i]}]:${system_oss[${machines_ip_list[i]}]}"
	echo "system_archs[${machines_ip_list[i]}]:${system_archs[${machines_ip_list[i]}]}"
	echo "system_timezones[${machines_ip_list[i]}]:${system_timezones[${machines_ip_list[i]}]}"
	echo "passwords[${machines_ip_list[i]}]:${passwords[${machines_ip_list[i]}]}"
done    



for ((i=0; i<${#xpanel_ip_list[@]}; i++))
do

	echo "xpanel_ports[${xpanel_ip_list[i]}]:${xpanel_ports[${xpanel_ip_list[i]}]}"

done    


}




function set_password(){


  for i in "${machines_ip_list[@]}"
  do
  if ssh -o BatchMode=yes $i exit &>/dev/null ;then
	output=$(expect <<EOF
	set timeout 3
	spawn  ssh -p${sshports[$i]} ${current_users[$i]}@$i "sudo passwd ${kunlun_users[$i]}"
	expect "New password:"
	send -- {${klustron_info[1]}}
	send "\n"
	expect "Retype new password:"
	send -- {${klustron_info[1]}}
	send "\n"
	expect eof

EOF
)

	else

	output=$(expect <<EOF
	set timeout 3
	spawn  ssh -p${sshports[$i]} ${current_users[$i]}@$i "sudo passwd ${kunlun_users[$i]}"
		expect {
				"yes/no" { send "yes\n"; exp_continue }
				"password" {
						send -- {${passwords[$i]}}
						send "\n"
	
				}
				eof { exit }
	
				}
		expect "New password:"
		send -- {${klustron_info[1]}}
		send "\n"
		expect "Retype new password:"
		send -- {${klustron_info[1]}}
		send "\n"
		expect eof

EOF
)	

fi 

result=$(echo "$output"|dos2unix|grep -ow  'successfully'|wc -l)
if [[ $result -ne 1 ]];then
	let set_password_count++;
	echo  -e "${GREEN_COLOR}========================================================$RES"
    echo -e "$RED_COLOR_UF错误:$RES"
	echo -e "$YELLOW_COLOR主机${i}昆仑账户${kunlun_users[$i]}密码设置失败$RES"
fi


done


#判断变量是否大于等于1,成立表示有机器系统昆仑用户密码设置失败,脚本退出
if [[ $set_password_count -ge 1 ]];then

  echo  -e "${GREEN_COLOR}========================================================$RES"
  exit
fi



}


function check_kunlun_user(){

command_list=$(command -v cp rm chown systemctl docker mkdir | sed 's/$/,/g' | sed '$ s/,$//'|xargs)
privileges_line="${klustron_info[0]}   ALL=(ALL)       NOPASSWD: ${command_list}"

if ! id ${klustron_info[0]} &>/dev/null; then 
  if sudo useradd ${klustron_info[0]} &>/dev/null;then
      if ! sudo egrep -q "^\b${klustron_info[0]}\b.*NOPASSWD: ALL$|^\b${klustron_info[0]}\b.*NOPASSWD: $a.*$" /etc/sudoers; then
          sudo sed -i "/^root/a$privileges_line" /etc/sudoers &>/dev/null
          if [[ $? == 0 ]]; then
              echo  "${klustron_info[0]} User created successfully" &>/dev/null
		  else
			  echo  "kunlun_sudo-Failed "
			  exit
          fi
      fi
  else
      echo  "kunlun_user-Failed "
      exit
  fi
  
else

  if ! sudo egrep -q "^\b${klustron_info[0]}\b.*NOPASSWD: ALL$|^\b${klustron_info[0]}\b.*NOPASSWD: $a.*$" /etc/sudoers; then
      sudo sed -i "/^root/a$privileges_line" /etc/sudoers  &>/dev/null
      if [[ $? == 0 ]]; then
          echo  "${klustron_info[0]} User created successfully" &>/dev/null
	  else
		  echo  "kunlun_sudo-Failed "
          exit		  
      fi
  else
      echo  "${klustron_info[0]} User created successfully" &>/dev/null
  fi


fi

}






function __main() {
    # 全局变量函数
    configure_global

    # 交互式输入信息
    interact_info $1
	check_machines_sshport_passwd
	configure_kunlun_config
	check_os
	check_arch
	check_zone
	print_array
	set_password
	check_kunlun_user

	
	
}


__main  $1