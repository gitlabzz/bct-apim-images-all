#! /bin/bash

echo
echo "----------- Building Base Image For Release ----------- "
tar xf APIGateway_7.7.20220228-DockerScripts-2.4.0.tar-28.02.2022.tar

./apigw-emt-scripts-2.4.0/build_base_image.py \
  --installer=APIGateway_7.7.20220228_Install_linux-x86-64_BN02.run-28.02.2022.run \
  --os=centos7 \
  --out-image=$2$3$4:$1

# create latest tag
#docker tag $2$3$4:$1 $2$3$4:latest

# push image with release tag
#docker push $2$3$4:$1

# push same image using 'latest' tag
#docker push $2$3$4:latest
