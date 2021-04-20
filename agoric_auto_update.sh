#!/bin/bash

currentChainVersion=$(curl 'http://localhost:26657/status?' | jq '.result.node_info.network')
networkChainVersion=$(curl 'https://testnet.agoric.net/network-config' | jq '.chainName')
# | tr -d \"

#Difference check chainName
if [ "$currentChainVersion" != "$networkChainVersion" ]
then
systemctl stop ag-chain-cosmos
cd $HOME
rm -rf $HOME/agoric-sdk
git clone https://github.com/Agoric/agoric-sdk -b $networkChainVersion | tr -d \"
cd $HOME/agoric-sdk
yarn install
yarn build
(cd packages/cosmic-swingset && make)
curl https://testnet.agoric.net/network-config > chain.json
chainName=`jq -r .chainName < chain.json`
curl https://testnet.agoric.net/genesis.json > $HOME/.ag-chain-cosmos/config/genesis.json 
ag-chain-cosmos unsafe-reset-all
peers=$(jq '.peers | join(",")' < chain.json)
seeds=$(jq '.seeds | join(",")' < chain.json)
sed -i.bak 's/^log_level/# log_level/' $HOME/.ag-chain-cosmos/config/config.toml
sed -i.bak -e "s/^seeds *=.*/seeds = $seeds/; s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.ag-chain-cosmos/config/config.toml
systemctl start ag-chain-cosmos
else
fi

