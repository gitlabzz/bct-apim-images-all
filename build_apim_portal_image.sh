#! /bin/bash

# ./build_apim_portal_image.sh harbor.com manaul_tag _snapshot 172.16.63.175 3306 api_portal api_portal_user changeme

# after removing $3
# ./build_apim_portal_image.sh harbor.com /apim /apim_portal 1234 172.16.63.175 3306 api_portal api_portal_user changeme

echo
echo "----------- Building API Portal Image ----------- "

tar xf APIPortal_7.7.20220228_Docker_Samples_Package_linux-x86-64_BN724.tar-28.02.2022.tar
mv apiportal-docker-* api_portal_build

docker image build \
  -t $1$2$3:$4 \
  --build-arg MYSQL_HOST=$5 \
  --build-arg MYSQL_PORT=$6 \
  --build-arg MYSQL_DATABASE=$7 \
  --build-arg MYSQL_USER=$8 \
  --build-arg MYSQL_PASSWORD=$9 \
  api_portal_build/

rm -rf api_portal_build

# create latest tag
#docker tag $1$2$3:$4 $1$2$3:latest

# push image with release tag
#docker push $1$2$3:$4

# push same image using 'latest' tag
#docker push $1$2$3:latest
