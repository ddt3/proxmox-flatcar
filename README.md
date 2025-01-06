# Create Flatcar VMs in ProxMox
This repository contains some scripts that I created for personal use. 
With these scripts I can create a flatcar VM on my proxmox cluster, using ignition files for set-up.

For these scripts to work a webserver is needed to serve the ignition files. The server address can be configured 

## Overview of the process steps and Folder structure
The following steps need to be performed

1. Create a Butane (yaml) file for a new flatcar vm
2. Run `create_vm.sh`<br>
It will automatically:
   1. Convert Butane file(s) to ignition files 
   2. Transfer the "start" ignition file to proxmox
   3. Create a VM using a flatcar image
   4. Add the ignition file to the VM
   5. Start the VM


The following folder stucture exists

```
 ┣ utils
 ┣ yaml
 ┃ ┣ include
 ┃ ┣ include-dockers
 
 ```

### Create a Butane file

To create a new VM a Butane (yaml) file with the name of the vm needs to be created in the yaml folder. This Butane file can include other yaml files. A template file, called `a.yaml.template` can be found in the utils folder, it should serve as a starting point.

A number of include files have been added: 
* `add-compose.yaml`<br>
Adds docker compose to flatcar
* `ssh.yaml`<br>
Adds public ssh key for user `core`, allowing for ssh access to a flatcar vm
* `music.yaml`<br>
Adds an NFS mount (my music library) to a flatcar vm
* `start-docker.yaml`<br>
Add a systemd unit file to automatically start the "dockers in the compose file"

Docker compose files are added in the folder `include-dockers`. A number of 
docker-compose.yml examples can be found in that folder

### Run `create_vm.sh`

`create_vm.sh` takes one parameter: the name of the VM to be created. It checks if a yaml file with the same name exists and will then proceed
#### Convert Butane file(s) to ignition files
The script `utils/yaml2ign.sh` will create ignition files for all yaml files. The folder stucture of the yaml files is copied for the ignition files. A docker is used for translating Butane to ignition. (as described in the flatcar documentation)

#### Transfer the "start" ignition file to proxmox
Simple wget from the webserver is used to place the first ignition file into a proxmox folder. A snippets folder can be used, because files in this folder are available to the whole cluster. Allowing flatcar vms to be migrated to another host in the cluster. 

In the ignition file the text `REPLACE` is replaced by the name of the VM. (this is used for e.g. hostname). Allowing yaml/ignition files with the same content but different names: to create similar vms with different host names.
#### Create a VM using a flatcar image
Latest flatcar image is downloaded (and also stored in the snippets folder). As flatcar automatically updates after start, it is not needed to update the flatcar image with each "deployment". But if that is necessary: just remove the flatcar image before starting the script.
#### Add the ignition file to the VM
In the script the following line:<br>
`qm set ${NewVMID} --args '-fw_cfg name=opt/com.coreos/config,file='${IGNITION}`<br>
causes the vm to use the ignition file, that is on the local snippets folder. This ignition file then includes all other files.

#### Start the VM
When starting the VM for the first time, the ignition process is performed. It might be that a few retries are needed to retrieve the included ignition files from the webserver. 

Note that starting the dockers in the docker compose, may take some time to. In the proxmox console tab, you can check if:
* A docker-compose.yaml is created in the core home folder
* docker-compose is available
* The docker compose is at work: `journalctl -f -u application.service`
* etc.

