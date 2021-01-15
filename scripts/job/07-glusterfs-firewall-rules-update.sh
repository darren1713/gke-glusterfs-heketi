#!/bin/sh

heketi_nodeport=$(kubectl get svc/heketi -n default -o jsonpath='{.spec.ports[0].nodePort}')

echo "Looking up GCP firewall rule for gke-[cluster name]-xxxx-ssh rule to file source ip's for GCP control plane servers, which will ultimately connect to heketi when a new storage class is created"
gcp_controlplane_ips=$(gcloud compute firewall-rules list --filter="allowed[].map().firewall_rule().list()=('tcp:22') AND name:('gke-$CLUSTER_NAME*')" --sort-by priority --format="table[no-heading]( sourceRanges.list() )")

echo "Google Control Plane IP's: $gcp_controlplane_ips"

second_counter=0
polling_delay_seconds=2

# ------------ [START] Wait for Heketi node port to be configured ------------ #
if [ -z "$heketi_nodeport" ]
then
  echo "Waiting for heketi node port to become available..."
fi

while [ -z "$heketi_nodeport" ]
do
  # Will update the same line in the shell until it finishes
  echo -e "\r[notice] $second_counter seconds have passed..."

  second_counter=$((second_counter + polling_delay_seconds))

  sleep $polling_delay_seconds

  heketi_nodeport=$(kubectl get svc/heketi -n default -o jsonpath='{.spec.ports[0].nodePort}')
done

echo "Heketi node port: $heketi_nodeport"
# ------------- [END] Wait for Heketi node port to be configured ------------- #

# ------------ [START] Update firewall rule with Heketi node port ------------ #
echo "Creating firewall rule..."

gcloud compute firewall-rules create allow-$CLUSTER_NAME-heketi \
  --allow "tcp:$heketi_nodeport" \
  --source-ranges="$gcp_controlplane_ips"
# ------------- [END] Update firewall rule with Heketi node port ------------- #
