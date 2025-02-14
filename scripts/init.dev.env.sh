#!/usr/bin/env bash

# COLOR
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# -----------------------------------
# Compile contracts and extract ABIs
# -----------------------------------

cd ./packages/govern-core/
yarn compile
yarn abi:extract

if [ $? -ne 0 ]
then
    echo " "
    echo -e "${RED}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "**                                                                                 **"
    echo "**            Not able to compile the contracts and extract the ABIs!              **"
    echo "**                                                                                 **"
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"

    exit 1
else
    echo " "
    echo -e "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "**                                                                              **"
    echo "**                    Contracts compiled and ABIs extracted                     **"
    echo "**                                                                              **"
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
fi

# ----------------------------------
# Init docker containers
# ----------------------------------

cd ../govern-server/

if [[ -d "./dev-data" ]]; then
    rm -rf ./dev-data
fi

mkdir -p ./dev-data/postgres
mkdir -p ./dev-data/ipfs

if [[ "$(docker ps -a | grep graph)" ]]; then
    yarn stop:containers
fi

yarn start:containers

if [ $? -ne 0 ]
then
    echo " "
    echo -e "${RED}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "**                                                                             **"
    echo "**                  Couldn't start all containers successfully                 **"
    echo "**                                                                             **"
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"

    exit 1
fi

# --------------------------------------------
# Wait some seconds until containers are ready
# --------------------------------------------
echo "Waiting until containers are ready..."

while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8030)" != "200" ]]; do sleep 5; done

echo " "
echo -e "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "**                                                                              **"
echo "**                    All containers started successfully                       **"
echo "**                                                                              **"
echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"

# ---------------------
# Create local subgraph
# ---------------------

cd ../govern-subgraph/
yarn create-local

if [ $? -ne 0 ]
then
    echo " "
    echo -e "${RED}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "**                                                                              **"
    echo "**                     Couldn't create the subgraph locally                     **"
    echo "**                                                                              **"
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"

    exit 1
else
    echo " "
    echo -e "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "**                                                                              **"
    echo "**                            Subgraph created locally                          **"
    echo "**                                                                              **"
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
fi

# -----------------------
# Deploy subgraph locally
# -----------------------
yarn deploy-local

if [ $? -ne 0 ]
then
    echo " "
    echo -e "${RED}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "**                                                                              **"
    echo "**                     Couldn't deploy the subgraph locally                     **"
    echo "**                                                                              **"
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"

    exit 1
else
    echo " "
    echo -e "${GREEN}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "**                                                                              **"
    echo "**                    Govern: local dev env initialized                         **"
    echo "**                                                                              **"
    echo "**      Execute from now on just 'yarn start:dev' in the root folder or         **"
    echo "**           'yarn start:containers' in the 'govern-server' package.            **"
    echo "**                                                                              **"
    echo -e ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${NC}"
fi
