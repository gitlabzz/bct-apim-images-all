#! /bin/bash

echo
echo "----------- Building API Manager for environment '$1' Using Base Image '$3'----------- "
tar xf APIGateway_7.7.20220228-DockerScripts-2.4.0.tar-28.02.2022.tar

# get the certificate from environment variable
echo "${APIMANAGER_LICENSE}" | base64 -d >license.lic
echo "----------- Using following license ----------- "
cat license.lic

echo "----------- coping groups for '$1' to merge-dir/apigateway/groups ----------- "
cp -r apimgr/groups/$1/groups apimgr/merge-dir/apigateway/

#1. dev
#2. 7_7_20220228_20220518_69
#3. /apim_base:latest
#4. harbor.com
#5. /apim_sit
#6. /apim_apig

./apigw-emt-scripts-2.4.0/build_gw_image.py \
  --license=license.lic \
  --domain-cert=apimgr/certs/$1/cert.pem \
  --domain-key=apimgr/certs/$1/key.pem \
  --domain-key-pass-file=apimgr/certs/$1/pass.txt \
  --merge-dir apimgr/merge-dir/apigateway \
  --pol=apimgr/policy/bct.pol \
  --env=apimgr/environment/$1/bct.env \
  --fed-pass-file=apimgr/nopass.txt \
  --parent-image=$4$5$3 \
  --group-id=axway-group \
  --out-image=$4$5$6:$2

# create latest tag
#docker tag $4$5$6:$2 $4$5$6:latest

# push image with release tag
#docker push $4$5$6:$2

# push same image using 'latest' tag
#docker push $4$5$6:latest
