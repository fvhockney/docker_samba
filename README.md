# samba

# Note:

This has been cloned from <https://github.com/ServerContainers/samba>. I have updated some settings in the conf that I prefer and removed references to `TimeMachine` because I am not an apple user. The README.md and Dockerfile are virtually unchanged.

this `master` branch or docker image with tag `latest` uses samba as package as provided by `debian:buster`.

This tagged version contains a freshly complied samba from official stable releases on debian:buster.
The Source Code is obtained from the following location: https://download.samba.org/pub/samba/stable/

Other then that the container features are kept the same.

## Environment variables and defaults

### Samba

* __GROUP\_groupname__
    * multiple variables/groups possible
    * adds a new group account with the given username and the env value as the group id
        * if you want to let the system assign the id then just provide a blank string
    * will fail if groupname or gid is already present

* __ACCOUNT\_username__
    * multiple variables/accounts possible
    * adds a new user account with the given username and the env value as password
    * the uid and gid are optional
    
* __username\_GID___
    * sets the GID of _username_ to the values
    * will fail if gid is not present

* __username\_UID__
    * sets the UID of _username_ to the values
    * will fail if uid is already assigned
    * on the debian image, uids start being assigned at 1000
        * if you set a user to 10000, then the _next_ user will git 10001 because of  how _useradd_ works

to restrict access of volumes you can add the following to your samba volume config:

    valid users = alice; invalid users = bob;

* __SAMBA\_CONF\_WORKGROUP__
    * default: _WORKGROUP_

* __SAMBA\_CONF\_SERVER\_STRING__
    * default: _file server_

* __SAMBA\_CONF\_MAP_TO_GUEST__
    * default: _Bad User_

* __SAMBA\_CONF\_ENABLE\_PASSWORD\_SYNC__
    * default not set - if set password sync is enabled

* __SAMBA\_VOLUME\_CONFIG\_myconfigname__
    * adds a new samba volume configuration
    * multiple variables/confgurations possible by adding unique configname to SAMBA_VOLUME_CONFIG_
    * examples
        * "[My Share]; path=/shares/myshare; guest ok = no; read only = no; browseable = yes"
        * "[Guest Share]; path=/shares/guests; guest ok = yes; read only = no; browseable = yes"

# Avahi / Zeroconf

## Infos:

* https://linux.die.net/man/5/avahi.service

You can't proxy the zeroconf inside the container to the outside, since this would need routing and forwarding to your internal docker0 interface from outside.

You can just expose the needed ports to the docker hosts port and install avahi.
After that just add a new service which fits to your config.

### Example Configuration

__/etc/avahi/services/smb.service__

    <?xml version="1.0" standalone='no'?>
    <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    <service-group>
     <name replace-wildcards="yes">%h</name>
     <service>
       <type>_smb._tcp</type>
       <port>445</port>
     </service>
     <service>
       <type>_device-info._tcp</type>
       <port>0</port>
       <txt-record>model=RackMac</txt-record>
     </service>
    </service-group>
