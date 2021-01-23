#!/bin/bash

# sleep 100000

# https://cloud.google.com/compute/docs/disks/add-persistent-disk
# https://cloud.google.com/sdk/gcloud/reference/compute/instances/attach-disk

gke_glusterfs_heketi_job_scripts_dir="$GLUSTER_HEKETI_BOOTSTRAP_DIR/scripts/job"

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


  #gcloud compute instances attach-disk $NODE --disk "${CLUSTER_NAME}-${ZONE}-disk-$n" --zone "$ZONE"

  #n=$(( $n + 1 ))

  #gcloud compute --project "$PROJECT_ID" disks create "${CLUSTER_NAME}-${ZONE}-disk-$n" \
  #  --size "$DISK_SIZE" \
  #  --zone "$ZONE" \
  #  --description "${CLUSTER_NAME}-gfs-k8s-brick" \
  #  --type "$DISK_TYPE"

  #gcloud compute instances attach-disk "$NODE" --disk "${CLUSTER_NAME}-${ZONE}-disk-$n" --zone "$ZONE"

  #n=$(( $n + 1 ))

  #gcloud compute --project "$PROJECT_ID" disks create "${CLUSTER_NAME}-${ZONE}-disk-$n" \
  #  --size "$DISK_SIZE" \
  #  --zone "$ZONE" \
  #  --description "${CLUSTER_NAME}-gfs-k8s-brick" \
  #  --type "$DISK_TYPE"

  #gcloud compute instances attach-disk "$NODE" --disk "${CLUSTER_NAME}-${ZONE}-disk-$n" --zone "$ZONE"

  echo ""
  echo " ================== [END] Create and attach disks for node $NODE ================== "
  echo ""

done
unset IFS

echo ""
echo "Deploy the daemonset to the nodes to attach disks and install gluster"
echo ""
sed -e "s/\$CLUSTER_NAME/gsattrack-gluster5-13/" $gke_glusterfs_heketi_job_scripts_dir/01-entrypoint.yaml > $gke_glusterfs_heketi_job_scripts_dir/01-entrypoint-deploy.yaml
kubectl apply -f $gke_glusterfs_heketi_job_scripts_dir/01-entrypoint-deploy.yaml --namespace=default
kubectl apply -f $gke_glusterfs_heketi_job_scripts_dir/01-daemonset-deploy.yaml --namespace=default


function wait-for-daemonset(){
    retries=90
    while [[ $retries -ge 0 ]];do
        ready=$(kubectl -n $1 get daemonset $2 -o jsonpath="{.status.numberReady}")
        required=$(kubectl -n $1 get daemonset $2 -o jsonpath="{.status.desiredNumberScheduled}")
        echo "This is slow... Ready $ready Required $required"
        if [[ $ready -eq $required ]];then
            #echo "Succeeded"
            break
        fi
        ((retries--))
        sleep 10
    done
}

echo ""
echo "This takes a LONG TIME, wait up to 15 minutes for the daemonset to apply"
echo ""
wait-for-daemonset default node-initializer

# ------------------ [END] Create disks and attach to nodes ------------------ #
