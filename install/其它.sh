useradd kunlun

sudo - kunlun

#控制机上生成密钥

sudo su - kunlun -c '
    if [[ ! -s $HOME/.ssh/id_rsa || ! -s $HOME/.ssh/id_rsa.pub ]]; then
        rm -f $HOME/.ssh/id_rsa $HOME/.ssh/id_rsa.pub $HOME/.ssh/authorized_keys &&
        ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa -q && \
        cat $HOME/.ssh/id_rsa.pub > $HOME/.ssh/authorized_keys && \
        chmod 600 $HOME/.ssh/authorized_keys
    else
        if [[ ! -s $HOME/.ssh/authorized_keys ]]; then
            cat $HOME/.ssh/id_rsa.pub > $HOME/.ssh/authorized_keys && \
            chmod 600 $HOME/.ssh/authorized_keys
        fi
    fi

    if ! crontab -l 2>/dev/null | grep -q "^.*find.*rm -fr" ; then
        (echo "0 2 * * * find $klustron_basedir/kunlun-node-manager-$klustron_VERSION/data/ -name 'backup*' -mtime +1 | xargs rm -fr  &>/dev/null") | crontab -
    fi
'







