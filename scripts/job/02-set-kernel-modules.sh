#!/bin/bash

# for required kernel modules and required glusterfs command (mount.glusterfs)
# https://github.com/gluster/gluster-kubernetes/blob/master/docs/setup-guide.md#infrastructure-requirements
# https://gluster.readthedocs.io/en/latest/Install-Guide/Install/
#
# for safe glusterfs deployment turn off auto update -> 'apk-mark hold glusterfs*'
# can corrupt disks if autoupdate runs after volumes provisioned
# https://www.cyberciti.biz/faq/howto-glusterfs-replicated-high-availability-storage-volume-on-ubuntu-linux/
#
# for latest available ppa
# https://launchpad.net/~gluster

# https://github.com/gluster/gluster-kubernetes/blob/master/docs/setup-guide.md

# -------- [START] Enable kernel modules and install glusterfs client -------- #
echo ""
echo " ========== [START] Enable kernel modules and install glusterfs client ========== "
echo ""

IFS=$'\n'

#Get list of nodes and zones as we have to create the disk in the correct zone for the correct node
for CLUSTERZONES in $(kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels."failure-domain\.beta\.kubernetes\.io/zone" --no-headers)
do
  # Parse (name,zone) --> $NODE, $ZONE
  IFS=$' ' read -r NODE ZONE <<<"${CLUSTERZONES}"
  echo -e "Node:  ${NODE}"
  echo -e "Zone:  ${ZONE}"
  echo ""

  echo ""
  echo " ======================== [START] Configuring $NODE ======================== "
  echo ""

  gcloud compute ssh "$NODE" \
    --zone "$ZONE" \
    --command "\
      sudo sh -c '\
        apt-get update && \
        apt-get -y install software-properties-common && \
        add-apt-repository -y ppa:gluster/glusterfs-5 && \
        apt-get update && \
        apt-get -y install glusterfs-client;
        apt-mark hold glusterfs*; \
        echo \"dm_snapshot\" >> /etc/modules && \
        modprobe dm_snapshot; \
        echo \"dm_mirror\" >> /etc/modules && \
        modprobe dm_mirror; \
        echo \"dm_thin_pool\" >> /etc/modules && \
        modprobe dm_thin_pool; \
        systemctl stop rpcbind.service; \
        systemctl disable rpcbind.service; \
    '"

  echo ""
  echo " ========================= [END] Configuring $NODE ========================= "
  echo ""
done
unset IFS

echo ""
echo " ========== [START] Enable kernel modules and install glusterfs client ========== "
echo ""
# -------- [END] Enable kernel modules and install glusterfs client -------- #
