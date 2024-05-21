#!/bin/bash


rnu=$((RANDOM % 21))
klustron_info=("$@")


if command -v curl &> /dev/null; then
	if ! curl -s --head www.kunlunbase.com | head -n 1 | grep "200 OK" > /dev/null; then
		echo   "Network-Erro "
		exit 
	fi

elif command -v ping &> /dev/null; then
	if ! ping -c 3 www.kunlunbase.com > /dev/null 2>&1; then
		echo   "Network-Erro "
		exit 
 
	fi
	
else
    echo  "Conn-Status "
	#echo  "使用命令安装:sudo yum -y install iputils curl"
	#echo  "使用命令安装:sudo apt update  && sudo apt install iputils-ping curl"
    exit 
fi



if [ $# -lt 4 ];then
  echo   "Param-Error "
  exit 
fi


shift 3
klustron_ip=("$@")




# 控制机上面创建kunlun用户,控制机和不在安装机器列表内

function check_kunlun_user(){


privileges_line="${klustron_info[0]}   ALL=(ALL)       NOPASSWD: ALL"

if ! id ${klustron_info[0]} &>/dev/null; then 
  sudo useradd ${klustron_info[0]} &>/dev/null && \
  if [[ $? == 0 ]]; then
      if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
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

  if ! sudo egrep -q "^${klustron_info[0]}.*NOPASSWD: ALL$" /etc/sudoers; then
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






function kunlun_basedir(){

if [[ ! -d  ${klustron_info[1]} ]];then

	sudo mkdir -p ${klustron_info[1]} &>/dev/null  && sudo chown -R ${klustron_info[0]}:${klustron_info[0]} ${klustron_info[1]}  &>/dev/null
	if [[ $? == 0 ]];then
		echo   "Database directory creation successful" &>/dev/null
	else
		echo   "kunlun_basedir-Failed "
		exit
	fi 
	
else
    if ! sudo chown -R ${klustron_info[0]}:${klustron_info[0]} ${klustron_info[1]}  &>/dev/null;then
		echo   "kunlun_basedir-Failed "
		exit
    fi

fi




}


function centos_env(){


sudo yum remove  -y  postfix mariadb-libs  &>/dev/null
if [[ $? == 0 ]];then
 echo   "postfix mariadb-libs Uninstallation successful" &>/dev/null
else
  echo   "postfix-mariadb_UninstallD "
fi 




if [[ -f  /etc/selinux/config ]];then
	if ! getenforce |grep -iq  Disabled;then
		sudo setenforce 0 &>/dev/null &&\
		sudo sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   &>/dev/null
		if [[ $? == 0 ]];then
	   		echo "SELINUX configuration successful" &>/dev/null
		else
	   		echo "SELINUX_config-Failed "  
		fi 
	fi
else 
  echo "SELINUX_Uninstall "
	
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
   echo "limits configuration successful"  &>/dev/null
	else
   echo "Limits_config-Failed "
		
	fi  

fi


 
sudo systemctl stop firewalld &>/dev/null && sudo systemctl disable firewalld   &>/dev/null
if [[ $? == 0 ]];then
  echo "The firewall has been closed successful"  &>/dev/null
	
else
  echo "Firewall_close-Failed "

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
	echo  \"Crontab-Failed \"
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





function kunlun_docker(){



# 检查 Docker 是否已安装



for i in "${klustron_ip[@]}" 
do
	
	if ip a|grep -wq $i ;then



			if [[ -f "/etc/os-release" ]]; then
				source /etc/os-release
				
				if [[ "$ID" == "centos" ]]; then
					
			
				
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
									echo  -e "Exist_Unable_start_Docker "
									exit
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
								echo  -e "Install_Unable_start_Docker "   
								exit 
							fi
							
						fi
				
					
				else
				
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
									echo  -e "Exist_Unable_start_Docker "
									exit
								fi
							fi
						else
							echo "Docker 未安装, 正在尝试安装 Docker." &>/dev/null
							sudo yum -y install docker &>/dev/null && \
							sudo systemctl start docker  &>/dev/null && \
							sudo systemctl enable docker &>/dev/null
							if sudo systemctl is-active --quiet docker; then
								echo "Docker 启动成功."   &>/dev/null
							else
								echo  -e "Install_Unable_start_Docker "   
								exit 
								
							fi
							
						fi		
					
				
				fi
				
			fi
	
	
	
	fi

done












}







}
function __main(){


check_kunlun_user
kunlun_basedir
kunlun_env
centos_env
kunlun_docker
}


__main


