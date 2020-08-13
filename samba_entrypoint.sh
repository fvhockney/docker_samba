#!/bin/sh

cat <<EOF
################################################################################
Welcome to the servercontainers/samba
################################################################################
EOF

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ]; then
    echo ">> CONTAINER: starting initialisation"

    if [ -z "$SAMBA_CONF_WORKGROUP" ]; then
        SAMBA_CONF_WORKGROUP="WORKGROUP"
        echo ">> SAMBA CONFIG: no \$SAMBA_CONF_WORKGROUP set, using '$SAMBA_CONF_WORKGROUP'"
    fi

    if [ -z "$SAMBA_CONF_SERVER_STRING" ]; then
        SAMBA_CONF_SERVER_STRING="file server"
        echo ">> SAMBA CONFIG: no \$SAMBA_CONF_SERVER_STRING set, using '$SAMBA_CONF_SERVER_STRING'"
    fi

    if [ -z "$SAMBA_CONF_MAP_TO_GUEST" ]; then
        SAMBA_CONF_MAP_TO_GUEST="Bad User"
        echo ">> SAMBA CONFIG: no \$SAMBA_CONF_MAP_TO_GUEST set, using '$SAMBA_CONF_MAP_TO_GUEST'"
    fi

    ##
    # SAMBA Configuration
    ##
    cat <<EOF > /etc/smb.conf
[global]
   server role = standalone server
   workgroup = $SAMBA_CONF_WORKGROUP
   server string = $SAMBA_CONF_SERVER_STRING
   map to guest = $SAMBA_CONF_MAP_TO_GUEST
   usershare max shares = 0
   deadtime = 30
   use sendfile = yes
   aio read size = 1
   aio write size = 1
   dns proxy = no
   log file = /dev/stdout
EOF

    ##
    # SAMBA Configuration (Password Sync)
    ##
    if [ "$SAMBA_CONF_ENABLE_PASSWORD_SYNC" = "true" ]; then
        echo ">> SAMBA CONFIG: \$SAMBA_CONF_ENABLE_PASSWORD_SYNC is set, enabling password sync"
        cat <<EOF >> /etc/smb.conf
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
EOF
    fi

    ##
    # GROUPS
    ##

    env | grep '^GROUP_' | while IFS= read -r I_GROUP; do
        GROUP_NAME=$(echo "$I_GROUP" | cut -d'=' -f1 | cut -d'_' --complement -f1 |tr '[:upper:]' '[:lower:]')
        GROUP_ID=$(echo "$I_GROUP" | cut -d'=' -f2)
        echo ">> GROUP: adding group: $GROUP_NAME"
        groupadd "$GROUP_NAME"
        if [ -n "$GROUP_ID" ]; then
            echo ">> GROUP: changing $GROUP_NAME id to $GROUP_ID"
            groupmod -g "$GROUP_ID" "$GROUP_NAME"
        fi
    done

        ##
        # USER ACCOUNTS
        ##
        env | grep '^ACCOUNT_' | while IFS= read -r I_ACCOUNT ; do
            ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | cut -d'_' -f2 | tr '[:upper:]' '[:lower:]')
            ACCOUNT_PASSWORD=$(echo "$I_ACCOUNT" | cut -d'=' --complement -f1)

            echo ">> ACCOUNT: adding account: $ACCOUNT_NAME"
            useradd -M -s /bin/false "$ACCOUNT_NAME"
            yes "$ACCOUNT_PASSWORD" | passwd "$ACCOUNT_NAME"
            yes "$ACCOUNT_PASSWORD" | smbpasswd -a "$ACCOUNT_NAME"
            unset "$(echo "$I_ACCOUNT" | cut -d'=' -f1)"

            env | grep -i "^$ACCOUNT_NAME" | while IFS= read -r I_SUP; do
                ACCOUNT_UID=$(echo "$I_SUP" | cut -d'=' --complement -f1)
                ACCOUNT_GID=$(echo "$I_SUP" | cut -d'=' --complement -f1)
                if [ -n "$ACCOUNT_UID" ]; then
                    echo ">> ACCOUNT: changing $ACCOUNT_NAME uid to $ACCOUNT_UID"
                    usermod -u "$ACCOUNT_UID" "$ACCOUNT_NAME"
                    unset "$(echo $I_SUP | cut -d'=' -f1)"
                fi
                if [ -n "$ACCOUNT_GID" ]; then
                    echo ">> ACCOUNT: changing $ACCOUNT_NAME gid to $ACCOUNT_GID"
                    usermod -g "$ACCOUNT_GID" "$ACCOUNT_NAME"
                    unset "$(echo $I_SUP | cut -d'=' -f1)"
                fi
            done
        done


        ##
        # Samba Vonlume Config ENVs
        ##
        env | grep '^SAMBA_VOLUME_CONFIG_' | while IFS= read -r I_CONF; do
            CONF_CONF_VALUE=$(echo "$I_CONF" | cut -d'=' --complement -f1)

            echo "$CONF_CONF_VALUE" | tr ';' '\n' >> /etc/smb.conf
            printf "\n\n" >> /etc/smb.conf
        done

        cp /etc/smb.conf /etc/samba/smb.conf
        touch "$INITALIZED"
        else
            echo ">> CONTAINER: already initialized - direct start of samba"
    fi

        ##
        # CMD
        ##
        echo ">> CMD: exec docker CMD"
        echo "$@"
        exec "$@"
