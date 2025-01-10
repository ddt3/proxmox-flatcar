######## This script:
# - Checks if the configuration file for a vm exists
# - Builds the ignition files 
# - Runs a script on the proxmox host to create a flatcar vm 
########

########
# First check if a VM name is provide as a parameter if not: exit the script and print a usage message.
VM_NAME=$1
if [ -z "$VM_NAME" ]; then
    echo "Usage: $0 VM_NAME"
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

########
# Set varaibales to your situation
######## 
PROXMOX_HOST=pve.familie-dokter.lan
PROXMOX_USER=root
IGNITION_UPLOAD=

PROXMOX_SCRIPT=${SCRIPT_DIR}/proxmox_create_vm.sh
IGN_SCRIPT=${SCRIPT_DIR}/yaml2ign.sh
YAML_DIR=/home/core/local/yaml
YAML_DIR=$(echo $SCRIPT_DIR | sed -e "s/\/utils/\/yaml/")
IGN_DIR=$(echo $SCRIPT_DIR | sed -e "s/\/utils/\/ign/")

YAML_FILE="${YAML_DIR}/${VM_NAME}.yaml"

# First check if yaml configuration with VMNAME does exist
if [ ! -f ${YAML_FILE} ]; then
    echo "ERROR: YAML configuration for VM ${VM_NAME} not found."
    exit 1
fi
########
# The actual script
########
# Build ignition files
${IGN_SCRIPT} ${YAML_DIR}

cat ${PROXMOX_SCRIPT} | ssh ${PROXMOX_USER}@${PROXMOX_HOST} bash -s $VM_NAME #