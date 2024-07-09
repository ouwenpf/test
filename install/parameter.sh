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

# Function to print usage
print_usage() {
    echo "Usage: $0 -h <host_ip> -P <port_ip> [-c '<content>'] [-w '<content>'] [-f <file>]"
}


# Function connection
connections_info() {

metadata_result=$(psql postgres://$c_user:$c_password@$host_ip:$port_ip/postgres -c "SELECT concat('-h',b.hostaddr,' -P',b.port) as master_conn_str from pg_cluster_meta_nodes  b  where is_master='t';"|sed '1d;2d;/rows/d;$d')

cluster_id=$(psql postgres://$c_user:$c_password@$host_ip:$port_ip/postgres -c "SELECT cluster_id  from pg_cluster_meta_nodes  b  where is_master='t';"|sed '1d;2d;/rows/d;$d'|sed '$d'|sed 's/^[ \t]*//;s/[ \t]*$//')

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
other_nodes=$(psql postgres://$c_user:$c_password@$host_ip:$port_ip/postgres -c "
SELECT 
    s.name,
    n.hostaddr,
    n.port,
    CASE
        WHEN n.id = s.master_node_id THEN '主'
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
function_a() {
connections_info


    local content=$@
    content=$(echo "$content"  | awk '{for(i=1; i<=NF; i++) {printf "name like '\''%%%s%%'\''", $i; if (i<NF) printf " or "}; printf "\n"}')
	
	server_nodes=$(mysql -u$s_user -p$s_password $metadata_connections 2>/dev/null -e "SELECT  concat('postgres://$c_user:$c_password@',hostaddr,':',port,'/postgres')  FROM kunlun_metadata_db.comp_nodes WHERE status='active' and db_cluster_id=$cluster_id;"|sed '1d')
	
	# mapfile -t 将查询结果按行存入数组 connections中
	mapfile -t server_connections <<< "$server_nodes"
    #echo ${server_connections[@]}
	for i in ${server_connections[*]} 
	do
	host_port=$(echo "$i"| awk -F'[@\/]' '{print $4 }')
    psql $i << EOF
	SELECT name 参数名称, setting "$host_port" FROM pg_settings WHERE $content;
EOF
	done
}

# Function to handle -w option
function_b() {
connections_info
    local content=$@
    echo "Executing function B with content: $content"
    # Add your logic here for -w
}

# Function to handle -f option
function_c() {
connections_info
    local file=$1
    if [ -f "$file" ]; then
        echo "Executing function C with file: $file"
        # Add your logic here for -f
    else
        echo "File not found: $file"
        exit 1
    fi
}

# Initialize variables
host_ip=""
port_ip=""
c_content=""
w_content=""
f_file=""
base_info_flag=true

# Parse command line arguments
while getopts ":h:P:c:w:f:" opt; do
  case $opt in
    h)
      host_ip=$OPTARG
      ;;
    P)
      port_ip=$OPTARG
      ;;
    c)
      if [ -n "$w_content" ] || [ -n "$f_file" ]; then
          echo "Options -c, -w, and -f cannot be used together."
          print_usage
          exit 1
      fi
      c_content=$OPTARG
      base_info_flag=false
      ;;
    w)
      if [ -n "$c_content" ] || [ -n "$f_file" ]; then
          echo "Options -c, -w, and -f cannot be used together."
          print_usage
          exit 1
      fi
      w_content=$OPTARG
      base_info_flag=false
      ;;
    f)
      if [ -n "$c_content" ] || [ -n "$w_content" ]; then
          echo "Options -c, -w, and -f cannot be used together."
          print_usage
          exit 1
      fi
      f_file=$OPTARG
      base_info_flag=false
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      print_usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      print_usage
      exit 1
      ;;
  esac
done

# Check if both IP and port are provided
if [ -z "$host_ip" ] || [ -z "$port_ip" ]; then
    echo "Missing required arguments"
    print_usage
    exit 1
fi

# Check if IP and port are valid
if validate_ip "$host_ip" && validate_port "$port_ip"; then
    if $base_info_flag; then
        base_info
    fi
else
    if ! validate_ip "$host_ip"; then
        echo "Invalid IP address: $host_ip"
    fi
    if ! validate_port "$port_ip"; then
        echo "Invalid port: $port_ip"
    fi
    exit 1
fi

# Execute functions based on -c, -w, and -f options
if [ -n "$c_content" ]; then
    function_a "$c_content"
elif [ -n "$w_content" ]; then
    function_b "$w_content"
elif [ -n "$f_file" ]; then
    function_c "$f_file"
fi




