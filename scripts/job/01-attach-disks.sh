#!/bin/bash

# sleep 100000

# https://cloud.google.com/compute/docs/disks/add-persistent-disk
# https://cloud.google.com/sdk/gcloud/reference/compute/instances/attach-disk

gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION"

# ----------------- [START] Create disks and attach to nodes ----------------- #
# Generate 3xN disks and attach them
#

IFS=$'\n'

#Get list of nodes and zones as we have to create the disk in the correct zone for the correct node
for CLUSTERZONES in $(kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels."failure-domain\.beta\.kubernetes\.io/zone" --no-headers)
do
  # Parse (name,zone) --> $NODE, $ZONE
  IFS=$' ' read -r NODE ZONE <<<"${CLUSTERZONES}"
  echo -e "Node:  ${NODE}"
  echo -e "Zone:  ${ZONE}"
  echo ""
  n=1

  echo ""
  echo " ================= [START] Create and attach disks for node $NODE in zone $ZONE ================= "
  echo ""

  gcloud compute --project "$PROJECT_ID" disks create "${CLUSTER_NAME}-${ZONE}-disk-$n" \
    --size "$DISK_SIZE" \
    --zone "$ZONE" \
    --description "${CLUSTER_NAME}-gfs-k8s-brick" \
    --type "$DISK_TYPE"

  gcloud compute instances attach-disk $NODE --disk "${CLUSTER_NAME}-${ZONE}-disk-$n" --zone "$ZONE"

  n=$(( $n + 1 ))

  gcloud compute --project "$PROJECT_ID" disks create "${CLUSTER_NAME}-${ZONE}-disk-$n" \
    --size "$DISK_SIZE" \
    --zone "$ZONE" \
    --description "${CLUSTER_NAME}-gfs-k8s-brick" \
    --type "$DISK_TYPE"

  gcloud compute instances attach-disk "$NODE" --disk "${CLUSTER_NAME}-${ZONE}-disk-$n" --zone "$ZONE"

  n=$(( $n + 1 ))

  gcloud compute --project "$PROJECT_ID" disks create "${CLUSTER_NAME}-${ZONE}-disk-$n" \
    --size "$DISK_SIZE" \
    --zone "$ZONE" \
    --description "${CLUSTER_NAME}-gfs-k8s-brick" \
    --type "$DISK_TYPE"

  gcloud compute instances attach-disk "$NODE" --disk "${CLUSTER_NAME}-${ZONE}-disk-$n" --zone "$ZONE"

  n=$(( $n + 1 ))

  echo ""
  echo " ================== [END] Create and attach disks for node $NODE ================== "
  echo ""

done
unset IFS

# ------------------ [END] Create disks and attach to nodes ------------------ #
