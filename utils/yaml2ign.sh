########
# This scrtipt creates ignition files from all YAML files in a specific folder.
# The itnitation files are create in a seperate folder (ign) mirroring the folder scructure of the YAML files.
########
if [ -z "$1" ]; then
    echo "Usage: $0 YAML_FOLDER"
    exit 1
else
    YAML_FOLDER=$(realpath $1)
fi


# Not that in this case IGN folder automatocally becomes: /home/core/local/ign

for yamlfile in $(find $YAML_FOLDER -type f -name "*.yaml" -exec realpath {} \;); 
    do
    # Replace the file extension from yaml to ign and create the ignition file in the ign folder.
    ignfile=$(echo ${yamlfile} | sed --expression=sx/yamlx/ignxg --expression=s/.yaml/.ign/g )
    mkdir -p $(dirname ${ignfile})
    # Use butane inside a docker, print name of yaml for fault finding
    if [ ${yamlfile} -nt ${ignfile} ] 
    then
        echo "-----${yamlfile} -----> ${ignfile} -----"
        cat ${yamlfile} | docker run --rm -i quay.io/coreos/butane:release > ${ignfile}
        echo -----end:${yamlfile}:-----
    else
        echo "${ignfile} is up to date"
    fi

done