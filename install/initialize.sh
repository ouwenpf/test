#!/bin/bash


COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
rnu=$((RANDOM % 21))
klustron_info=("$@")

if ! curl -s --head www.kunlunbase.com | head -n 1 | grep "200 OK" > /dev/null; then
    echo  -e "$COL_START$RED当前主机网络异常$COL_END"
    exit
    
elif [ $# -ne 3 ];then
  echo  -e "$COL_START${RED}Usage:  缺少昆仑用户,目录和版本信息$COL_END"
  exit 
fi
    






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
system_type() {


operating_system=$(detect_system_type)

# 使用 if 语句判断函数返回值，并进行相应的操作
if [[ "$operating_system" == "Ubuntu" ]]; then
    echo "Detected Ubuntu system."
    # 在此处添加针对 Ubuntu 系统的操作
elif [[ "$operating_system" == "CentOS" ]]; then
    echo "Detected CentOS system."
    echo  -e "$COL_START${RED}CentOS$COL_END"
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



# 初始化kunlun环境变量
function kunlun_env(){

sudo -E su - ${klustron_info[0]} -c "

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
function __main(){

control_env
control_kunlun
kunlun_env

}


__main


