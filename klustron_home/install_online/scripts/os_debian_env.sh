#!/bin/bash


function configure_global(){

rnu=$((RANDOM % 21))
klustron_info=("$@")

if command -v curl &> /dev/null; then
	if ! curl -s --head www.kunlunbase.com | head -n 1 | grep "200 OK" > /dev/null; then
		echo   "Network-Erro"
		exit 
	fi

elif command -v ping &> /dev/null; then
	if ! ping -c 3 www.kunlunbase.com > /dev/null 2>&1; then
		echo   "Network-Erro"
		exit 
 
	fi
	
elif [ $# -ne 3 ];then
  echo   "Param-Error"
  exit 

else
    echo  "Conn-Status"
	#echo  "使用命令安装:sudo yum -y install iputils curl"
	#echo  "使用命令安装:sudo apt update  && sudo apt install iputils-ping curl"
    exit 
fi

    
}




function fetch_os_series() {

if command -v apt &> /dev/null; then
    echo 'Debian'
elif command -v yum &> /dev/null; then
    echo 'Red-Hat'
elif command -v zypper &> /dev/null; then
    echo 'SUSE' 
else
    echo "Unknown system"
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
	elif [[ "$ID" == "bclinux" ]]; then
        echo "bclinux"	
	elif [[ "$ID" == "opencloudos" ]]; then
        echo "opencloudos"		
    else
        echo "Unknown system"
    fi
    
else
    echo "Unknown-system"
fi

}




# 检查主机操作系统类型
system_type() {


operating_system=$(detect_system_type)

# 使用 if 语句判断函数返回值，并进行相应的操作
if [[ "$operating_system" == "ubuntu" ]]; then
    echo "Detected Ubuntu system."
    # 在此处添加针对 Ubuntu 系统的操作
elif [[ "$operating_system" == "centos" ]]; then
    echo "Detected CentOS system."
    echo  -e "$COL_START${RED}CentOS$COL_END"
    # 在此处添加针对 CentOS 系统的操作
elif [[ "$operating_system" == "kylin" ]]; then
    echo "Detected kylin system."
    # 在此处添加针对 kylin 系统的操作
elif [[ "$operating_system" == "bclinux" ]]; then
    echo "Detected kylin system."
    # 在此处添加针对 bclinux 系统的操作
elif [[ "$operating_system" == "opencloudos" ]]; then
    echo "Detected opencloudos system."
    # 在此处添加针对 opencloudos 系统的操作
else
    echo "Unknown-system"
    exit
fi


}




# 控制机上面设置必要的环境,否则脚本无法正确安装


function control_env(){

operating_system=$(detect_system_type)

# 使用 if 语句判断函数返回值，并进行相应的操作
if [[ "$operating_system" == "centos" || "$operating_system" == "bclinux" || "$operating_system" == "opencloudos" ]]; then
    #echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in  expect dos2unix jq nc; do
        if ! command -v "$i" &> /dev/null; then
            sudo yum install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                #echo  -e "$COL_START${RED}$i命令安装失败$COL_END"        
                echo  -e "$COL_START${RED}${i}-Install-Failed$COL_END"
                exit
            fi
        fi
    done
elif [[ "$operating_system" == "ubuntu" ]]; then
    #echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in figlet expect dos2unix jq netcat; do
        if ! command -v "$i" &> /dev/null; then
            sudo apt-get install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                #echo  -e "$COL_START${RED}$i命令安装失败$COL_END"        
                echo  -e "$COL_START${RED}${i}-Install-Failed$COL_END"
                exit
            fi
        fi
    done
elif [[ "$operating_system" == "kylin" ]]; then
    #echo  -e "$COL_START${YELLOW}正在检查系统环境.....$COL_END"
    for i in  expect dos2unix jq nc; do
        if ! command -v "$i" &> /dev/null; then
            sudo yum install -y $i &>/dev/null
            if [[ $? -ne 0 ]]; then
                #echo  -e "$COL_START${RED}$i命令安装失败$COL_END"        
                echo  -e "$COL_START${RED}${i}-Install-Failed$COL_END"
                exit
            fi
        fi
    done
else
    echo "Unknown-system"
    exit
fi





}



# 控制机上面创建kunlun用户,控制机和不在安装机器列表内

function control_kunlun(){


operating_system=$(detect_system_type)
privileges_line="${klustron_info[0]}   ALL=(ALL)       NOPASSWD: ALL"

# 使用 if 语句判断函数返回值，并进行相应的操作


if [[ "$operating_system" == "centos" || "$operating_system" == "bclinux" || "$operating_system" == "opencloudos" ]]; then
  if ! id ${klustron_info[0]} &>/dev/null; then 
    sudo useradd ${klustron_info[0]} &>/dev/null && \
    if [[ $? == 0 ]]; then
        if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
            sudo sed -i "/^root/a$privileges_line" /etc/sudoers 
            if [[ $? == 0 ]]; then
                echo -e "${COL_START}${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
            fi
        fi
    else
        echo -e "${COL_START}${RED}${klustron_info[0]} kunlun_user-Failed$COL_END"
        exit
    fi
  else
    if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
        sudo sed -i "/^root/a$privileges_line" /etc/sudoers  
        if [[ $? == 0 ]]; then
            echo -e "${COL_START}${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
        fi
    else
        echo -e "${COL_START}${GREEN}${klustron_info[0]} User created successfully$COL_END" &>/dev/null
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
        echo -e "$COL_START${RED}${klustron_info[0]}kunlun_user-Failed$COL_END"
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
    echo "Unknown-system"
    exit
fi




}


function kunlun_basedir(){

if [[ ! -d  ${klustron_info[1]} ]];then

	sudo mkdir -p ${klustron_info[1]} &>/dev/null  && sudo chown -R ${klustron_info[0]}:${klustron_info[0]} ${klustron_info[1]}  &>/dev/null
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}Database directory creation successful$COL_END" &>/dev/null
	else
   echo  -e "$COL_START${RED}kunlun_basedir-Failed$COL_END"
   exit
	fi 
else
    if ! sudo chown -R ${klustron_info[0]}:${klustron_info[0]} ${klustron_info[1]}  &>/dev/null;then
    echo  -e "$COL_START${RED}kunlun_basedir-Failed$COL_END"
    fi

fi




}


function centos_env(){


sudo yum remove  -y  postfix mariadb-libs  &>/dev/null
if [[ $? == 0 ]];then
 echo  -e "$COL_START${GREEN}postfix mariadb-libs Uninstallation successful$COL_END" &>/dev/null
else
  echo  -e "$COL_START${GREEN}postfix-mariadb_Uninstall$COL_END"
fi 




if [[ -f  /etc/selinux/config ]];then
	if ! getenforce |grep -iq  Disabled;then
		sudo setenforce 0 &>/dev/null &&\
		sudo sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   &>/dev/null
		if [[ $? == 0 ]];then
	   		echo  -e "$COL_START${GREEN}SELINUX configuration successful$COL_END" &>/dev/null
		else
	   		echo  -e "$COL_START${RED}SELINUX_config-Failed$COL_END"  
		fi 
	fi
else 
  echo  -e "$COL_START${GREEN}SELINUX_Uninstall$COL_END"
	
fi


if [[ -f  /etc/security/limits.conf ]];then
  if ! egrep -iq '*^.*hard.*200000$'  /etc/security/limits.conf;then
  
sudo bash -c 'cat >> /etc/security/limits.conf << EOF

*                soft    nproc         1000000
*                hard    nproc         1000000
*                soft    nofile        200000
*                hard    nofile        200000

EOF'
  fi
  
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}limits configuration successful$COL_END"  &>/dev/null
	else
   echo  -e "$COL_START${RED}Limits_config-Failed$COL_END"
		
	fi  

fi


 
sudo systemctl stop firewalld &>/dev/null && sudo systemctl disable firewalld   &>/dev/null
if [[ $? == 0 ]];then
  echo  -e "$COL_START${GREEN}The firewall has been closed successful$COL_END"  &>/dev/null
	
else
  echo  -e "$COL_START${RED}Firewall_close-Failed$COL_END"

fi 






# 检查 Docker 是否已安装
if command -v docker &>/dev/null; then
    echo "Docker 已安装." &>/dev/null
    
    # 检查 Docker 是否正在运行
    if sudo systemctl is-active --quiet docker; then
        echo "Docker 正在运行."  &>/dev/null
    else
        echo "Docker 未运行, 正在尝试启动 Docker." &>/dev/null
        sudo systemctl start docker &>/dev/null
        if sudo systemctl is-active --quiet docker; then
            echo "Docker 启动成功."   &>/dev/null
        else
        	echo  -e "$COL_START${RED}Unable_start_Docker$COL_END"
        fi
    fi
else
    echo "Docker 未安装, 正在尝试安装 Docker." &>/dev/null
    sudo yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo  &>/dev/null && \
    sudo yum -y install docker-ce docker-ce-cli containerd.io &>/dev/null && \
	sudo systemctl start docker  &>/dev/null && \
    sudo systemctl enable docker &>/dev/null
	if sudo systemctl is-active --quiet docker; then
       echo "Docker 启动成功."   &>/dev/null
    else
       echo  -e "$COL_START${RED}Install_Unable_start_Docker$COL_END"      
    fi
	
fi




}



function ubutun_env(){

sudo apt-get remove  -y  postfix mariadb-libs  &>/dev/null
if [[ $? == 0 ]];then
 echo  -e "$COL_START${GREEN}postfix mariadb-libs Uninstallation successful$COL_END" &>/dev/null
else
  echo  -e "$COL_START${GREEN}postfix-mariadb_Uninstall$COL_END"
fi 




if [[ -f  /etc/selinux/config ]];then
	if ! getenforce |grep -iq  Disabled;then
		sudo setenforce 0 &>/dev/null &&\
		sudo sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   &>/dev/null
		if [[ $? == 0 ]];then
	   		echo  -e "$COL_START${GREEN}SELINUX configuration successful$COL_END" &>/dev/null
		else
	   		echo  -e "$COL_START${RED}SELINUX_config-Failed$COL_END"  
		fi 
	fi
else 
  echo  -e "$COL_START${GREEN}SELINUX_Uninstall$COL_END"
	
fi



if [[ -f  /etc/security/limits.conf ]];then
  if ! egrep -iq '*^.*hard.*200000$'  /etc/security/limits.conf;then
  
sudo bash -c 'cat >> /etc/security/limits.conf << EOF

*                soft    nproc         1000000
*                hard    nproc         1000000
*                soft    nofile        200000
*                hard    nofile        200000

EOF'
  fi
  
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}limits configuration successful$COL_END"  &>/dev/null
	else
   echo  -e "$COL_START${RED}Limits_config-Failed$COL_END"
		
	fi  

fi




sudo ufw disable &>/dev/null &&  sudo systemctl disable ufw &>/dev/null
if [[ $? == 0 ]];then
  echo  -e "$COL_START${GREEN}The firewall has been closed successful$COL_END"  &>/dev/null
	
else
  echo  -e "$COL_START${RED}Firewall_close-Failed$COL_END"

fi 



# 检查 Docker 是否已安装
if command -v docker &>/dev/null; then
    echo "Docker 已安装." &>/dev/null
    
    # 检查 Docker 是否正在运行
    if sudo systemctl is-active --quiet docker; then
        echo "Docker 正在运行."  &>/dev/null
    else
        echo "Docker 未运行, 正在尝试启动 Docker." &>/dev/null
        sudo systemctl start docker &>/dev/null
        if sudo systemctl is-active --quiet docker; then
            echo "Docker 启动成功."   &>/dev/null
        else
        	echo  -e "$COL_START${RED}Unable_start_Docker$COL_END"
        fi
    fi
else
    echo "Docker 未安装, 正在尝试安装 Docker." &>/dev/null
    sudo apt update  &>/dev/null && \
    sudo apt install -y docker.io  &>/dev/null && \
	sudo systemctl start docker  &>/dev/null && \
    sudo systemctl enable docker &>/dev/null
	if sudo systemctl is-active --quiet docker; then
       echo "Docker 启动成功."   &>/dev/null
    else
       echo  -e "$COL_START${RED}Install_Unable_start_Docker$COL_END"      
    fi
	
fi




}






# 初始化kunlun环境变量
function kunlun_env(){

sudo -E su - ${klustron_info[0]}  -c '
if [ ! -f ~/.my.cnf ]; then
    echo -e "[mysql]\nno-auto-rehash\nprompt=\"\\\\\\u@\\\\\\h [\\\\\\d]>\"" > ~/.my.cnf
fi
'




sudo -E su - ${klustron_info[0]} -c "

if  command -v crontab &>/dev/null; then
    if ! crontab -l 2>/dev/null | grep -q \"^.*${klustron_info[1]}/kunlun-node-manager-${klustron_info[2]}/data.*backup\" ; then
		  crontab -l 2>/dev/null > /tmp/crontab_tmp 
      echo \"0 2 * * * find ${klustron_info[1]}/kunlun-node-manager-${klustron_info[2]}/data/ -name 'backup*' -mtime +7 | xargs rm -fr  &>/dev/null\" >> /tmp/crontab_tmp && \
		  crontab 2>/dev/null /tmp/crontab_tmp && \
		  sudo rm -f /tmp/crontab_tmp  &>/dev/null
	else
		sudo rm -f /tmp/crontab_tmp  &>/dev/null
		
    fi
else
	echo -e \"\e[31mCrontab-Failed\e[0m\"
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




function base_env(){

operating_system=$(detect_system_type)

# 使用 if 语句判断函数返回值，并进行相应的操作
if [[ "$operating_system" == "centos" ]]; then
	centos_env
elif [[ "$operating_system" == "bclinux" ]]; then
	centos_env
elif [[ "$operating_system" == "opencloudos" ]]; then
	centos_env
elif [[ "$operating_system" == "ubuntu" ]]; then
	ubutun_env
elif [[ "$operating_system" == "kylin" ]]; then
	centos_env
else
    echo "Unknown-system"
    exit
fi


}






}
function __main(){

control_env
control_kunlun
kunlun_basedir
kunlun_env
base_env
}


__main


