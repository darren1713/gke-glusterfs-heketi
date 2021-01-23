#!/bin/sh

# https://cloud.google.com/compute/docs/machine-types

# --------------------- [START] Create Kubernetes cluster -------------------- #
echo ""
echo " ====================== [START] Creating Kubernetes cluster ======================= "
echo ""
echo "      CLOUDSDK_PROJECT_NAME: $project_name"
echo "      CLOUDSDK_CLUSTER_NAME: $cluster_name"
echo "      CLOUDSDK_COMPUTE_REGION: $region"
echo "      CLUSTER_VERSION:       $cluster_version"
echo "      NODE_COUNT:            $node_count"
echo "      MACHINE_TYPE:          $machine_type"
echo ""

# gcloud container --project "$PROJECT_ID" clusters create "$CLUSTER_NAME" --cluster-version "$CLUSTER_VERSION" --quiet \
cluster_version_option=''
if [ ! -z "$cluster_version" ]
then
  cluster_version_option="--cluster-version $cluster_version"
fi

# Add node-labels tag pre-emptively even though gke-deploy also tags the nodes,
# because recreation/updates of the nodes erases labels set with kubectl label
gcloud container --project "$project_name" clusters create "$cluster_name" $cluster_version_option --quiet \
    --region "$region" \
    --machine-type "$machine_type" \
    --image-type=ubuntu \
    --disk-size '20' \
    --scopes bigquery,storage-full,userinfo-email,compute-rw,cloud-source-repos,https://www.googleapis.com/auth/cloud-platform,datastore,service-control,service-management,sql,sql-admin,https://www.googleapis.com/auth/appengine.admin,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/calendar,https://www.googleapis.com/auth/plus.login,https://www.googleapis.com/auth/ndev.clouddns.readwrite \
    --num-nodes "$node_count" \
    --network 'default' 
    --node-labels=storagenode=glusterfs
#    --zone "$zone" \
#    --enable-private-nodes \
#    --enable-ip-alias \
#    --master-ipv4-cidr 172.16.0.32/28
#    --enable-cloud-endpoints \
#    --no-enable-cloud-logging \
#    --no-enable-cloud-monitoring

echo ""
echo " ======================= [END] Creating Kubernetes cluster ======================== "
echo ""

# Set context to new cluster
gcloud container clusters get-credentials "$cluster_name" --region "$region" --project "$project_name"
# ---------------------- [END] Create Kubernetes cluster --------------------- #



# --------------------- [START] Add packages -------------------- #
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
  echo " ======================== [START] Configuring $NODE software-properties-common ======================== "
  echo ""

  gcloud compute ssh "$NODE" \
    --zone "$ZONE" \
    --command "\
      sudo sh -c '\
        apt-get update && apt-get install software-properties-common -y \
        '"
  echo ""
  echo " ========================= [END] Configuring $NODE ========================= "
  echo ""
done
# ---------------------- [END] Add packages --------------------- #
