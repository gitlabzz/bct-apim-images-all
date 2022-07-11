#! /bin/bash

#./build_anm_image.sh sit 7_7_20220228_20220518_8 /apim_base:latest harbor.com /apim_sit /apim_anm

echo
echo "----------- Building Admin Node Manager for environment '$1' ----------- "
tar xf APIGateway_7.7.20220228-DockerScripts-2.4.0.tar

# get the certificate from environment variable
echo "${APIGATEWAY_LICENSE}" | base64 -d >license.lic
echo "----------- Using following license ----------- "
cat license.lic

echo
echo "Using version: $(./apigw-emt-scripts-2.4.0/build_anm_image.py --version)"
echo

echo "----------- coping conf for '$1' to merge-dir/analytics/conf ----------- "
cp -r anm/confs/$1/conf anm/merge-dir/apigateway/
echo

./apigw-emt-scripts-2.4.0/build_anm_image.py \
  --license=license.lic \
  --domain-cert=anm/certs/$1/cert.pem \
  --domain-key=anm/certs/$1/key.pem \
  --domain-key-pass-file=anm/certs/$1/pass.txt \
  --fed=anm/fed/$1/anm.fed \
  --fed-pass-file=anm/fed/$1/pass.txt \
  --merge-dir anm/merge-dir/apigateway \
  --metrics \
  --anm-username=api-sit-axway  \
  --anm-pass-file=anm/anm.pass.txt \
  --parent-image=$4$5$3 \
  --out-image=$4$5$6:$2

# create latest tag
#docker tag $4$5$6:$2 $4$5$6:latest

# push image with release tag
#docker push $4$5$6:$2

# push same image using 'latest' tag
#docker push $4$5$6:latest
