#!/bin/bash

machines_ip_list=(172.16.125.15 172.16.125.16 172.16.125.17)
control_machines=(root 123456 22)
klustron_info=(kunlun)

for remote_host in "${machines_ip_list[@]}"
do
    # 复制 .ssh 文件夹到远程主机
    expect <<EOF
        set timeout 300
        spawn sudo scp -rp -P${control_machines[2]} /home/${klustron_info[0]}/.ssh ${control_machines[0]}@$remote_host:/home/${klustron_info[0]}/
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- "${control_machines[1]}"
                send "\n"
            }
        }
        expect eof
EOF

    # 更改 .ssh 文件夹的权限
    expect <<EOF
        set timeout 300
        spawn sudo ssh  -p${control_machines[2]} ${control_machines[0]}@$remote_host "sudo chown -R ${klustron_info[0]}:${klustron_info[0]} /home/${klustron_info[0]}/.ssh"
        expect {
            "yes/no" { send "yes\n"; exp_continue }
            "password" {
                send -- "${control_machines[1]}"
                send "\n"
            }
        }
        expect eof
EOF

    # 检查 SSH 连接是否成功
 ssh_output=$(sudo -E su - kunlun -c "ssh -p ${control_machines[2]} ${klustron_info[0]}@$remote_host 'echo Successful SSH connection'")

    if [[ "$ssh_output" == "Successful SSH connection" ]]; then
        echo "SSH 连接成功: $remote_host"
    else
        echo "SSH 连接失败: $remote_host"
    fi

done

