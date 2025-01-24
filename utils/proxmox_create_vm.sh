########
# This script takes one parameter: the name (which is also the hostname) of the new VM
########
if [[ $# -ne 1 ]] ; then
    printf "Usage:\n $0 <VM Name>\n"
    exit 0
fi

########
# Config, change to your own needs
########
IGNDIR="/mnt/pve/NFS-USB/snippets"
BaseIGNFileURL="http://www-fc.familie-dokter.lan/ign/"
IMAGE="${IGNDIR}/flatcar_production_qemu_image.img"

########
# Variables 
########
NAME=$1
IGNFileURL=${BaseIGNFileURL}${NAME}.ign
IGNITION="${IGNDIR}/${NAME}.ign"


########
# Retrieve an available vm id
########
NewVMID=$(pvesh get /cluster/nextid)

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

wget ${IGNFileURL} --output-document=${IGNITION}.tmp

# Make sure the correct hostname is used for the VMN
cat ${IGNITION}.tmp | sed --expression=s/REPLACE/${NAME}/g > ${IGNITION}
rm ${IGNITION}.tmp

########
# Now create the Vm with the proper name using the available id
########

qm create ${NewVMID} --name ${NAME} --cores 2 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
qm set ${NewVMID} --scsi0 OneTB:0,import-from=${IMAGE}
qm set ${NewVMID} --boot order=scsi0
qm set ${NewVMID} --serial0 socket --vga qxl
qm set ${NewVMID} --agent enabled=1
qm set ${NewVMID} --args '-fw_cfg name=opt/org.flatcar-linux/config,file='${IGNITION} # make sure the " bootstrap ignition file" is used
echo "---------------------------------------"
echo VM: ${NAME} id:${NewVMID} has been created
echo "---------------------------------------"
# qm start ${NewVMID}                                                                             