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
        echo "centos"
    elif [[ "$ID" == "ubuntu" ]]; then
        echo "ubuntu"
    elif [[ "$ID" == "kylin" ]]; then
        echo "kylin"
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
if [[ "$operating_system" == "ubuntu" ]]; then
    echo "Detected ubuntu system."
    # 在此处添加针对 Ubuntu 系统的操作
elif [[ "$operating_system" == "centos" ]]; then
    echo "Detected centos system."
    # 在此处添加针对 CentOS 系统的操作
elif [[ "$operating_system" == "kylin" ]]; then
    echo "Detected kylin system."
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
if [[ "$operating_system" == "centos" ]]; then
    echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in  expect dos2unix jq nc; do
        if ! command -v "$i" &> /dev/null; then
            sudo yum install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
				exit
            fi
        fi
    done
elif [[ "$operating_system" == "ubuntu" ]]; then
    echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in figlet expect dos2unix jq netcat; do
        if ! command -v "$i" &> /dev/null; then
            sudo apt-get install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
				exit
            fi
        fi
    done
elif [[ "$operating_system" == "kylin" ]]; then
    echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in  expect dos2unix jq nc; do
        if ! command -v "$i" &> /dev/null; then
            sudo yum install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
				exit
            fi
        fi
    done
else
    echo -e "$COL_START${RED}Unknown-system$COL_END"
    exit
fi





}





# 控制机上面创建kunlun用户,控制机和不在安装机器列表内

function control_kunlun(){


operating_system=$(detect_system_type)
privileges_line="${klustron_info[0]}   ALL=(ALL)       NOPASSWD: ALL"

# 使用 if 语句判断函数返回值，并进行相应的操作


if [[ "$operating_system" == "centos" ]]; then
  if ! id ${klustron_info[0]} &>/dev/null; then 
    sudo useradd ${klustron_info[0]} &>/dev/null && \
    if [[ $? == 0 ]]; then
        if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
            sudo sed -i "/^root/a$privileges_line" /etc/sudoers 
            if [[ $? == 0 ]]; then
                echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
            fi
        fi
    else
        echo -e "$COL_START${RED}${klustron_info[0]} kunlun_user-Failed$COL_END"
        exit
    fi
  else
    if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
        sudo sed -i "/^root/a$privileges_line" /etc/sudoers  
        if [[ $? == 0 ]]; then
            echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
        fi
    else
        echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
    fi
  fi


elif [[ "$operating_system" == "ubuntu" ]]; then
  if ! id ${klustron_info[0]} &>/dev/null; then 
    sudo useradd -r -m -s /bin/bash  $klustron_user  &>/dev/null   &&\
    if [[ $? == 0 ]]; then
        if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
            sudo sed -i "/^root/a$privileges_line" /etc/sudoers 
            if [[ $? == 0 ]]; then
                echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
            fi
        fi
    else
        echo -e "$COL_START${RED}${klustron_info[0]} kunlun_user-Failed$COL_END"
        exit
    fi
  else
    if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
        sudo sed -i "/^root/a$privileges_line" /etc/sudoers  
        if [[ $? == 0 ]]; then
            echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
        fi
    else
        echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
    fi
  fi

elif [[ "$operating_system" == "kylin" ]]; then
  if ! id ${klustron_info[0]} &>/dev/null; then 
    sudo useradd ${klustron_info[0]} &>/dev/null && \
    if [[ $? == 0 ]]; then
        if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
            sudo sed -i "/^root/a$privileges_line" /etc/sudoers 
            if [[ $? == 0 ]]; then
                echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
            fi
        fi
    else
        echo -e "$COL_START${RED}${klustron_info[0]} kunlun_user-Failed$COL_END"
        exit
    fi
  else
    if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
        sudo sed -i "/^root/a$privileges_line" /etc/sudoers  
        if [[ $? == 0 ]]; then
            echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
        fi
    else
        echo -e "$COL_START${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
    fi
  fi

else
	echo -e "$COL_START${RED}Unknown-system$COL_END"
    exit
fi





}



# 控制机上面创建kunlun用户秘钥
function kunlun_secret_key(){

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



function kunlun_softwares(){


sudo -E su - ${klustron_info[0]} -c "

echo -e \"\e[33m正在下载昆仑安装程序......\e[0m\"  #&>/dev/null

if [[ ! -d  /home/${klustron_info[0]}/softwares/cloudnative ]]; then
    git clone https://gitee.com/zettadb/cloudnative.git /home/${klustron_info[0]}/softwares/cloudnative &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo -e \"\e[32m昆仑安装程序下载成功\e[0m\"  #&>/dev/null
    else 
        echo -e \"\e[31m昆仑安装程序下载失败\e[0m\"
        exit
    fi
else
    echo -e \"\e[32m最新程序下载成功\e[0m\"  #&>/dev/null
fi
"

}







#函数分发脚本,为每个机器安装klustron数据库必要环境.

function host_initialize(){


if sudo test -s /home/${klustron_info[0]}/softwares/cloudnative/cluster/install_scripts/initialize.sh ;then
  sudo cp -rp /home/${klustron_info[0]}/softwares/cloudnative/cluster/install_scripts/initialize.sh  /tmp/  && \
  sudo chown ${control_machines[0]}:${control_machines[0]}  /tmp/initialize.sh

  for i in "${machines_ip_list[@]}"
  do
    # 复制 initialize.sh到远程主机
output=$(expect <<EOF
  set timeout 3
  spawn  scp -rp -P${control_machines[2]} /tmp/initialize.sh ${control_machines[0]}@$i:/tmp/

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
    echo -e "$COL_START${RED}文件initialize.sh拷贝到${control_machines[0]}@$i失败$COL_END"
    #变量接收分发脚本失败的函数
    let count_host_initialize++
  fi

  

  done
  
  # 判断变量值如果大于等于1表示有机器分发脚本失败,为了保证每个机器安装顺利进行,脚本退出
  if [[ $count_host_initialize -ge 1 ]];then 
    exit
  else
    echo -e "$COL_START${GREEN}第三步:文件拷贝成功$COL_END" &>/dev/null
  fi

  
  
  
else
  echo -e "$COL_START${RED}文件initialize.sh不存在$COL_END"
  exit 
fi



}



# 在安装昆仑数据库的机器上初始化环境
function execute_initialize(){

echo  -e "$COL_START${YELLOW}正在初始化机器需要一点时间,请耐心等待,请勿中断.......$COL_END" 
echo  -e "$COL_START${RED}=================================$COL_END"

for i in "${machines_ip_list[@]}"
do
    # 执行initialize.sh脚本
   output=$(expect <<EOF #&>/dev/null
        set timeout 300
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo bash /tmp/initialize.sh ${klustron_info[@]} && sudo rm -f /tmp/initialize.sh"
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


 result_ip=$(echo "$output"|dos2unix|awk '{print $4}'|awk -F '@'  '{print $2}')
 result_error=$(echo "$output"|dos2unix|tr "'"  " "|xargs -n 1|egrep -vw "${control_machines[0]}@$i|s|password\:|initialize.sh"|awk 'NR>12')
 result_array=("$result_ip" "$result_error")

 for k in "${result_array[@]}"; do
    echo "$k"
 done
echo  -e "$COL_START${RED}=================================$COL_END"

done





}







function configure_Key(){

sudo cp -ra /home/${klustron_info[0]}/.ssh /tmp/ && \
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
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo cp -ra /tmp/.ssh /home/${klustron_info[0]}"
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
        spawn  ssh  -p${control_machines[2]} ${control_machines[0]}@$i "sudo chown -R ${klustron_info[0]}:${klustron_info[0]} /home/${klustron_info[0]}/.ssh"
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





function test_1(){

sudo -E su - ${klustron_info[0]} -c  "
cd \$HOME/softwares/cloudnative/cluster/clustermgr/

urls=(
    \"http://zettatech.tpddns.cn:14000/thirdparty/efk/elasticsearch-7.10.1.tar.gz\"
    \"http://zettatech.tpddns.cn:14000/thirdparty/efk/filebeat-7.10.1-linux-x86_64.tar.gz\"
    \"http://zettatech.tpddns.cn:14000/thirdparty/efk/kibana-7.10.1.tar.gz\"
    \"http://zettatech.tpddns.cn:14000/thirdparty/hadoop-3.3.1.tar.gz\"
    \"http://zettatech.tpddns.cn:14000/thirdparty/jdk-8u131-linux-x64.tar.gz\"
    \"http://zettatech.tpddns.cn:14000/thirdparty/mysql-connector-python-2.1.3.tar.gz\"
    \"http://zettatech.tpddns.cn:14000/thirdparty/prometheus.tgz\"
    \"http://zettatech.tpddns.cn:14000/thirdparty/haproxy-2.5.0-bin.tar.gz\"
)

for url in \"\${urls[@]}\"; do
    filename=\$(basename \"\$url\")
    if  [[ -f \$filename ]];then
        if ! curl -s \"\$url\"|diff - \"\$filename\";then
            rm -f \"\$filename\"  && \
            wget  \"\$url\"
        fi
        else
            wget  \"\$url\"
        fi
done
"

}


function test_2(){

sudo -E su - ${klustron_info[0]} -c  "

cd \$HOME/softwares/cloudnative/cluster/clustermgr/
urls=(
    \"http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/docker-images/kunlun-xpanel-${klustron_info[2]}.tar.gz\"
    \"http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/enterprise/kunlun-cdc-${klustron_info[2]}.tgz\"
    \"http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/enterprise/kunlun-proxysql-${klustron_info[2]}.tgz\"
    \"http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/enterprise/kunlun-cluster-manager-${klustron_info[2]}.tgz\"
    \"http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/enterprise/kunlun-node-manager-${klustron_info[2]}.tgz\"
    \"http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/enterprise/kunlun-server-${klustron_info[2]}.tgz\"
    \"http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/enterprise/kunlun-storage-${klustron_info[2]}.tgz\"
)

for url in \"\${urls[@]}\"; do
    filename=\$(basename \"\$url\")
    if  [[ -f \$filename ]];then
        if ! curl -s \"\$url\"|diff - \"\$filename\";then
            rm -f \"\$filename\"  && \
            wget  \"\$url\"
        fi
        else
            wget  \"\$url\"
        fi
done
"


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
  echo -e "$COL_START${RED}主机架构不一致$COL_END"
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
  echo -e "$COL_START${RED}主机系统不一致$COL_END"
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
  echo -e "$COL_START${RED}主机时区不一致$COL_END" 
  exit
fi

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
		eof { exit }
	
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
            "imageType": "file"
        }
EOF
)





if sudo test ! -s /home/${klustron_info[0]}/softwares/cloudnative/cluster/klustron_config.json ;then
# 生成完整的 JSON 配置文件
#sudo bash -c "cat <<EOF > /home/${klustron_info[0]}/softwares/cloudnative/cluster/klustron_config.json
sudo bash -c "cat <<EOF > /home/${klustron_info[0]}/softwares/cloudnative/cluster/klustron_config.json
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

sudo chown ${klustron_info[0]}:${klustron_info[0]} /home/${klustron_info[0]}/softwares/cloudnative/cluster/klustron_config.json


fi

}










# 客户交互输入基本信息,用户名,密码端口,服务器IP,数据库版本等信息
function __main() {

# 全局变量函数
base_env

# 判断系统类型函数
#system_type




# 客户交互式输入开始
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
    read -t 300 -s -r -p "请输入$username用户密码: " password
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
    #只保留最前面一个斜杆和去掉最后面所有斜杆
    basedir=$(echo "$basedir" | sed 's:^/\{2,\}:/:; s:/\+$::')
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

    # 控制机器环境函数
	control_env

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
    
	
    # 控制机创建昆仑用户函数
    control_kunlun
	
	# 下载昆仑数据库程序
    kunlun_softwares
    
	#生成配置文件
    klustron_config
	
    # 创建昆仑用户秘钥
    kunlun_secret_key
    
    # 分发脚本
    host_initialize
    # 初始化环境
    execute_initialize
    
    # 配置kunlun用户免密
    configure_Key
    
    test_1
    test_2
}





 __main

