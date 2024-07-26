#!/bin/bash

c_user='abc'
c_password='abc'
s_user='clustmgr'
s_password='clustmgr_pwd'

# Function to validate IP address
validate_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Function to validate port number
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [[ $port -ge 1 && $port -le 65535 ]]; then
        return 0
    else
        return 1
    fi
}


# Function to display usage
usage() {
    echo "Usage: $0 -h<host> -P<port> [-pc <params>] [-pw <params>] [-mc <params>] [-mw <params>] [-fp <file>] [-fm <file>]"
    exit 1
}


# Function connection
connections_info() {

metadata_result=$(psql postgres://$c_user:$c_password@$com_host:$com_port/postgres -c "SELECT concat('-h',b.hostaddr,' -P',b.port) as master_conn_str from pg_cluster_meta_nodes  b  where is_master='t';"|sed '1d;2d;/rows/d;$d')

cluster_id=$(psql postgres://$c_user:$c_password@$com_host:$com_port/postgres -c "SELECT cluster_id  from pg_cluster_meta_nodes  b  where is_master='t';"|sed '1d;2d;/rows/d;$d'|sed '$d'|sed 's/^[ \t]*//;s/[ \t]*$//')

# mapfile -t 将查询结果按行存入数组 connections中
mapfile -t metadata_connections <<< "$metadata_result"



}






# Function to execute base_info
base_info() {

RED='\033[0;31m'
NC='\033[0m' # No Color
connections_info

comp_nodes=$(mysql -u$s_user -p$s_password $metadata_connections 2>/dev/null -e "
SELECT 'computer' AS name, hostaddr, port, db_cluster_id AS master_node_id 
FROM kunlun_metadata_db.comp_nodes 
WHERE status='active' and db_cluster_id=$cluster_id;
")

# PostgreSQL查询
other_nodes=$(psql postgres://$c_user:$c_password@$com_host:$com_port/postgres -c "
SELECT 
    s.name,
    n.hostaddr,
    n.port,
    CASE
        WHEN n.id = s.master_node_id THEN concat('主','_',s.id)
        ELSE '备机'
    END AS master_node_id
FROM 
    pg_shard s
JOIN 
    pg_shard_node n ON s.id = n.shard_id

UNION

SELECT 
    'metadata' AS name,  
    hostaddr,
    port,
    CASE
        WHEN is_master = 't' THEN '主' 
        ELSE '备机'
    END AS master_node_id   
FROM 
    pg_cluster_meta_nodes   

ORDER BY 
    name,
    master_node_id,
    hostaddr;
" | sed '/rows/d;$d')

# 合并查询结果，并格式化输出
{
    echo -e "${RED}name\thostaddr\tport\tmaster_node_id${NC}"
    echo "$comp_nodes" | awk -v RED="$RED" -v NC="$NC" 'NR>1 {
        print RED $1 "\t" $2 "\t" $3 "\t" $4 NC;
    }'
    echo "$other_nodes" | awk -F'|' -v RED="$RED" -v NC="$NC" 'NR>2 {
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        gsub(/^[ \t]+|[ \t]+$/, "", $3);
        gsub(/^[ \t]+|[ \t]+$/, "", $4);
        print RED $1 "\t" $2 "\t" $3 "\t" $4 NC;
    }'
} | column -t -s $'\t'

}



# Function to handle -c option
function_pc() {
connections_info


    input_parameter=$@
    input_parameter=$(echo "$input_parameter"  | awk '{for(i=1; i<=NF; i++) {printf "name like '\''%%%s%%'\''", $i; if (i<NF) printf " or "}; printf "\n"}')
	
	server_nodes=$(mysql -u$s_user -p$s_password $metadata_connections 2>/dev/null -e "SELECT  concat('postgres://$c_user:$c_password@',hostaddr,':',port,'/postgres')  FROM kunlun_metadata_db.comp_nodes WHERE status='active' and db_cluster_id=$cluster_id;"|sed '1d')
	
	# mapfile -t 将查询结果按行存入数组 connections中
	mapfile -t server_connections <<< "$server_nodes"
    #echo ${server_connections[@]}
	for i in ${server_connections[*]} 
	do
	host_port=$(echo "$i"| awk -F'[@/]' '{print $4 }')
    psql $i << EOF
	SELECT name 参数名称, setting "$host_port" FROM pg_settings WHERE $input_parameter;
EOF
	done
}


function_pw() {
connections_info


    input_parameter=$@
	# 去掉等号两边的空格
	input_parameter=$(echo "$input_parameter" | sed 's/ *= */=/g')
	
	# 初始化输出字符串
	output_parameter=""
	
	# 使用空格分隔符将输入字符串拆分为数组
	IFS=' ' read -r -a array <<< "$input_parameter"
	
	# 遍历数组，构建输出字符串
	for item in "${array[@]}"; do
	output_parameter+="alter system set $item;"
	done
	
	# 打印结果
	echo -e "$output_parameter"
	
	
	server_nodes=$(mysql -u$s_user -p$s_password $metadata_connections 2>/dev/null -e "SELECT  concat('postgres://$c_user:$c_password@',hostaddr,':',port,'/postgres')  FROM kunlun_metadata_db.comp_nodes WHERE status='active' and db_cluster_id=$cluster_id;"|sed '1d')
	
	# mapfile -t 将查询结果按行存入数组 connections中
	mapfile -t server_connections <<< "$server_nodes"
    #echo ${server_connections[@]}
	
	cluster_host_port=$(mysql -u$s_user -p$s_password $metadata_connections 2>/dev/null -e "select  concat(hostaddr,':',port) from kunlun_metadata_db.cluster_mgr_nodes where member_state='source';"|sed '1d')

	
	for i in ${server_connections[*]} 
	do
		host_port=$(echo "$i"| awk -F'[@/]' '{print $4 }')
		echo $host_port
		psql $i << EOF
		$output_parameter
EOF
	done
	
	
	
    while true; do
        read -p "计算节点需要重新参数才能生效,是否重启? (Yy/Nn): " yn
        case $yn in
            [Yy]* ) 
                for i in ${server_connections[*]} 
				do	
					nodes_ip=$(echo "$i"| awk -F'[@/]' '{print $4 }'  |awk -F ':' '{print $1}')
					nodes_port=$(echo "$i"| awk -F'[@/]' '{print $4 }'|awk -F ':' '{print $2}')
					echo "计算节点$nodes_ip:$nodes_port重启中..."

					job_id=$(
						curl -d "
						{
						\"user_name\": \"super_dba\",
						\"job_id\": \"\",
						\"job_type\": \"control_instance\",
						\"version\": \"1.0\",
						\"timestamp\": \"1718337162853\",
						\"paras\": {
							\"control\": \"restart\",
							\"hostaddr\": \"$nodes_ip\",
							\"port\": \"$nodes_port\",
							\"cluster_id\": \"$cluster_id\",
							\"machine_type\": \"computer\"
						}
						}
						" -X POST http://$cluster_host_port/HttpService/Emit 2>&1 | awk -F ',' '{if ($6 != "") print $4}' | awk -F '"' '{print $4}'
						)
					
					sleep 10
					
					job_type=$(curl -d "
						{
						\"job_type\": \"get_status\",
						\"version\": \"1.0\",
						\"job_id\": \"$job_id\",
						\"timestamp\": \"1718337384462\",
						\"paras\": {}
						}
						" -X POST http://$cluster_host_port/HttpService/Emit 2>&1 | awk -F ',' '{if ($6 != "") print $6}' | awk -F '"' '{print $4}')
					
					
					if [[ "$job_type"  == "done" ]];then
						echo "重启成功"
					elif [[ "$job_type"  == "ongoing" ]];then
						echo "正在重启中......请稍后"
					elif [[ "$job_type"  == "failed" ]];then
						echo "重启失败"
					fi
											
				done
				
                break
                ;;
            [Nn]* ) 
                echo "不重启节点。"
                break
                ;;
            * ) 
                echo "请输入 Yy 或 Nn。"
                ;;
        esac
    done	
}


function_mc() {
connections_info


input_parameter=$@
input_parameter=$(echo "$input_parameter"  | awk '{for(i=1; i<=NF; i++) {printf "VARIABLE_NAME like '\''%%%s%%'\''", $i; if (i<NF) printf " or "}; printf "\n"}')

# 执行查询并将结果存入数组
mysql_result=$(psql postgres://$c_user:$c_password@$com_host:$com_port/postgres -c "SELECT concat('-h',b.hostaddr,' -P',b.port) FROM pg_shard a JOIN pg_shard_node b ON a.id = b.shard_id WHERE a.db_cluster_id = $cluster_id;" |sed '1d;2d;/rows/d;$d')

# mapfile -t 将查询结果按行存入数组 connections中
mapfile -t connections <<< "$mysql_result"


# 循环处理数组中的连接信息(修改存储节点参数)
for i in "${connections[@]}"; do
	host_port=$(echo "$i"| awk -F '[-hP]'  '{print $3":"$5}'| tr -d ' ')
	mysql -u$s_user -p$s_password $i  2>/dev/null  -e "
	select VARIABLE_NAME 参数名称, VARIABLE_VALUE  as '$host_port' from performance_schema.global_variables where $input_parameter;"
	 

done 



}



function_mw() {
connections_info



    input_parameter=$@
	# 去掉等号两边的空格
	input_parameter=$(echo "$input_parameter" | sed 's/ *= */=/g')
	
	# 初始化输出字符串
	output_parameter=""
	
	# 使用空格分隔符将输入字符串拆分为数组
	IFS=' ' read -r -a array <<< "$input_parameter"
	
	# 遍历数组，构建输出字符串
	for item in "${array[@]}"; do
	output_parameter+="set persist $item;"
	done
	
	# 打印结果
	echo -e "$output_parameter"

# 执行查询并将结果存入数组
mysql_result=$(psql postgres://$c_user:$c_password@$com_host:$com_port/postgres -c "SELECT concat('-h',b.hostaddr,' -P',b.port) FROM pg_shard a JOIN pg_shard_node b ON a.id = b.shard_id WHERE a.db_cluster_id = $cluster_id;" |sed '1d;2d;/rows/d;$d')

# mapfile -t 将查询结果按行存入数组 connections中
mapfile -t connections <<< "$mysql_result"


# 循环处理数组中的连接信息(修改存储节点参数)
for i in "${connections[@]}"; do
	host_port=$(echo "$i"| awk -F '[-hP]'  '{print $3":"$5}'| tr -d ' ')
  echo $host_port
	mysql -u$s_user -p$s_password $i  2>/dev/null << EOF
  $output_parameter

EOF

done

}




function_fp() {

connections_info


    input_parameter=$@
	# 去掉等号两边的空格
	input_parameter=$(cat "$input_parameter" | sed 's/ *= */=/g')
	
	# 初始化输出字符串
	output_parameter=""
	
	#mapfile -t 将查询结果按行存入数组array中
	mapfile -t array  <<< "$input_parameter"

	
	# 遍历数组，构建输出字符串
	for item in "${array[@]}"; do
	output_parameter+="alter system set $item;"
	done
	
	# 打印结果
	# echo -e "$output_parameter"
	
	
	server_nodes=$(mysql -u$s_user -p$s_password $metadata_connections 2>/dev/null -e "SELECT  concat('postgres://$c_user:$c_password@',hostaddr,':',port,'/postgres')  FROM kunlun_metadata_db.comp_nodes WHERE status='active' and db_cluster_id=$cluster_id;"|sed '1d')
	
	# mapfile -t 将查询结果按行存入数组 connections中
	mapfile -t server_connections <<< "$server_nodes"
    #echo ${server_connections[@]}
	
	cluster_host_port=$(mysql -u$s_user -p$s_password $metadata_connections 2>/dev/null -e "select  concat(hostaddr,':',port) from kunlun_metadata_db.cluster_mgr_nodes where member_state='source';"|sed '1d')
	
	
	for i in ${server_connections[*]} 
	do
		host_port=$(echo "$i"| awk -F'[@/]' '{print $4 }')
		echo $host_port
		psql $i << EOF
		$output_parameter
EOF
	done
	
	
	
    while true; do
        read -p "计算节点需要重新参数才能生效,是否重启? (Yy/Nn): " yn
        case $yn in
            [Yy]* ) 
                for i in ${server_connections[*]} 
				do	
					nodes_ip=$(echo "$i"| awk -F'[@/]' '{print $4 }'  |awk -F ':' '{print $1}')
					nodes_port=$(echo "$i"| awk -F'[@/]' '{print $4 }'|awk -F ':' '{print $2}')
					echo "计算节点$nodes_ip:$nodes_port重启中..."

					job_id=$(
						curl -d "
						{
						\"user_name\": \"super_dba\",
						\"job_id\": \"\",
						\"job_type\": \"control_instance\",
						\"version\": \"1.0\",
						\"timestamp\": \"1718337162853\",
						\"paras\": {
							\"control\": \"restart\",
							\"hostaddr\": \"$nodes_ip\",
							\"port\": \"$nodes_port\",
							\"cluster_id\": \"$cluster_id\",
							\"machine_type\": \"computer\"
						}
						}
						" -X POST http://$cluster_host_port/HttpService/Emit 2>&1 | awk -F ',' '{if ($6 != "") print $4}' | awk -F '"' '{print $4}'
						)
					
					sleep 10
					
					job_type=$(curl -d "
						{
						\"job_type\": \"get_status\",
						\"version\": \"1.0\",
						\"job_id\": \"$job_id\",
						\"timestamp\": \"1718337384462\",
						\"paras\": {}
						}
						" -X POST http://$cluster_host_port/HttpService/Emit 2>&1 | awk -F ',' '{if ($6 != "") print $6}' | awk -F '"' '{print $4}')
					
					
					if [[ "$job_type"  == "done" ]];then
						echo "重启成功"
					elif [[ "$job_type"  == "ongoing" ]];then
						echo "正在重启中......请稍后"
					elif [[ "$job_type"  == "failed" ]];then
						echo "重启失败"
					fi
											
				done
				
                break
                ;;
            [Nn]* ) 
                echo "不重启节点。"
                break
                ;;
            * ) 
                echo "请输入 Yy 或 Nn。"
                ;;
        esac
    done	




}



function_fm() {
connections_info



    input_parameter=$@
	# 去掉等号两边的空格
	input_parameter=$(cat "$input_parameter" | sed 's/ *= */=/g')
	
	# 初始化输出字符串
	output_parameter=""
	
	# 使用空格分隔符将输入字符串拆分为数组
	mapfile -t array <<< "$input_parameter"
	
	# 遍历数组，构建输出字符串
	for item in "${array[@]}"; do
	output_parameter+="set persist $item;"
	done
	
	# 打印结果
	#echo -e "$output_parameter"

# 执行查询并将结果存入数组
mysql_result=$(psql postgres://$c_user:$c_password@$com_host:$com_port/postgres -c "SELECT concat('-h',b.hostaddr,' -P',b.port) FROM pg_shard a JOIN pg_shard_node b ON a.id = b.shard_id WHERE a.db_cluster_id = $cluster_id;" |sed '1d;2d;/rows/d;$d')

# mapfile -t 将查询结果按行存入数组 connections中
mapfile -t connections <<< "$mysql_result"


# 循环处理数组中的连接信息(修改存储节点参数)
for i in "${connections[@]}"; do
	host_port=$(echo "$i"| awk -F '[-hP]'  '{print $3":"$5}'| tr -d ' ')
  echo $host_port
	mysql -u$s_user -p$s_password $i  2>/dev/null << EOF
  $output_parameter

EOF

done

}







# Initialize variables
com_host=""
com_port=""
pc_params=()
pw_params=()
mc_params=()
mw_params=()
fp_file=()
fm_file=()
base_info_flag=true
# Parse options using while loop
while [[ $# -gt 0 ]]; do
    case $1 in
        -h*)
            com_host="${1:2}"
            shift
            ;;
        -P*)
            com_port="${1:2}"
            shift
            ;;
        -pc)
            if [[ -n "$2" && "$2" != -* ]]; then
				base_info_flag=false
                pc_params+=("$2")
                shift 2
            else
                echo "Option -pc requires a parameter."
                usage
            fi
            ;;
        -pw)
            if [[ -n "$2" && "$2" != -* ]]; then
				base_info_flag=false
                pw_params+=("$2")
                shift 2
            else
                echo "Option -pw requires a parameter."
                usage
            fi
            ;;
        -mc)
            if [[ -n "$2" && "$2" != -* ]]; then
				base_info_flag=false
                mc_params+=("$2")
                shift 2
            else
                echo "Option -mc requires a parameter."
                usage
            fi
            ;;
        -mw)
            if [[ -n "$2" && "$2" != -* ]]; then
				base_info_flag=false
                mw_params+=("$2")
                shift 2
            else
                echo "Option -mw requires a parameter."
                usage
            fi
            ;;
        -fp)
            if [[ -n "$2" && "$2" != -* ]]; then
				base_info_flag=false
                fp_file="$2"
                shift 2
            else
                echo "Option -fp requires a parameter."
                usage
            fi
            ;;
        -fm)
            if [[ -n "$2" && "$2" != -* ]]; then
				base_info_flag=false
                fm_file="$2"
                shift 2
            else
                echo "Option -fm requires a parameter."
                usage
            fi
            ;;
        *)
            echo "Invalid option: $1" >&2
            usage
            ;;
    esac
done







# Ensure -h and -P are provided
if [[ -z "$com_host" || -z "$com_port" ]]; then
    echo "Error: -h and -P are required."
    usage
fi



# Check if IP and port are valid
if validate_ip "$com_host" && validate_port "$com_port"; then
    if $base_info_flag; then
        base_info
    fi
else
    if ! validate_ip "$com_host"; then
        echo "Invalid IP address: $com_host"
    fi
    if ! validate_port "$com_port"; then
        echo "Invalid port: $com_port"
    fi
    exit 1
fi



# Check for mutually exclusive parameters
count=0
[[ "${#pc_params[@]}" -gt 0 ]] && ((count++))
[[ "${#pw_params[@]}" -gt 0 ]] && ((count++))
[[ "${#mc_params[@]}" -gt 0 ]] && ((count++))
[[ "${#mw_params[@]}" -gt 0 ]] && ((count++))
[[ "${#fp_file[@]}" -gt 0 ]] && ((count++))
[[ "${#fm_file[@]}" -gt 0 ]] && ((count++))

if [[ $count -gt 1 ]]; then
    echo "Error: -pc, -pw, -mc, -mw, -fp, and -fm are mutually exclusive."
    usage
fi

# Display the parsed values
echo "Host: $com_host"
echo "Port: $com_port"
if [[ "${#pc_params[@]}" -gt 0 ]]; then
    function_pc "${pc_params[@]}"

fi

if [[ "${#pw_params[@]}" -gt 0 ]]; then
    function_pw "${pw_params[@]}"
fi

if [[ "${#mc_params[@]}" -gt 0 ]]; then
    function_mc "${mc_params[@]}"
fi

if [[ "${#mw_params[@]}" -gt 0 ]]; then
	function_mw "${mw_params[@]}"

fi



if [[ "${#fp_file[@]}" -gt 0 ]]; then
    if [[ -f "${fp_file[0]}" ]]; then
        function_fp "${fp_file[0]}"
    else
        echo "${fp_file[0]}:No such file or directory"
        exit 1
    fi
fi

if [[ "${#fm_file[@]}" -gt 0 ]]; then
    if [[ -f "${fm_file[0]}" ]]; then
        function_fm "${fm_file[0]}"
    else
        echo "${fm_file[0]}:No such file or directory"
        exit 1
    fi
fi

# Add your code logic here
