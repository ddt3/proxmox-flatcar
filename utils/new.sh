########
# This script takes one parameter: the name (which is also the hostname) of the new VM
########
if [[ $# -ne 1 ]] ; then
    printf "Usage:\n $0 <VM Name>\n"
    exit 0
fi

NAME=$1
########
# Config 
########
TMPDIR="/tmp"
IGNFileURL="http://www-fc.familie-dokter.lan/ign/boot/bootstrap.ign"
IMAGE="${TMPDIR}/flatcar_production_qemu_image.img"
IGNBOOT="${TMPDIR}/bootstrap.ign"

########
# Retrieve an available vm id
########
ID=$(pvesh get /cluster/nextid)

########
# Download  Flatcar image if it does not yet exist
########
if [ ! -f $IMAGE ]; then
    wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img --output-document=${IMAGE}
    file ${IMAGE}
fi
########
# Download "bootstrap ignation file":
# This ign file is used to set the host name and to retrieve the actual ignition file that contains the configuration for the new flatcar vm
########
wget ${IGNFileURL} --output-document=${IGNBOOT}

########
# Use the actual name of the vm in "bootstrap ignition file", which will allow flatcar to retrieve the proper ignition file during startup
########

IGNITION="${TMPDIR}/${NAME}.ign"
cat ${IGNBOOT} | sed --expression=s/REPLACE/$1/g > ${IGNITION}

qm create ${ID} --name ${NAME} --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm set ${ID} --scsi0 OneTB:0,import-from=${IMAGE}
qm set ${ID} --boot order=scsi0
qm set ${ID} --serial0 socket --vga qxl
qm set ${ID} --agent enabled=1
qm set ${ID} --args '-fw_cfg name=opt/com.coreos/config,file='${IGNITION}
qm start ${ID}                                                                             
