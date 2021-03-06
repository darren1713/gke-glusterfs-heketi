#!/bin/sh

deploy_path="$GLUSTER_HEKETI_BOOTSTRAP_DIR/gluster-kubernetes/deploy"

# ---------------- [START] Deploy GlusterFS DaemonSet, Heketi ---------------- #
cd "$deploy_path"

gk-deploy -gvy --admin-key $HEKETI_KEYADMIN --user-key $HEKETI_KEYUSER --gluster-image-name $GLUSTER_IMAGE_NAME
# ----------------- [END] Deploy GlusterFS DaemonSet, Heketi ----------------- #
