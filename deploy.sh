#!/bin/zsh
set -ex

./generate.sh

#find scripts -type f -iname "*.js" -exec npx hardhat run {} + || true
npx hardhat run scripts/12_Vault_role_setup_deploy_initial.js --network localhost
npx hardhat run scripts/13_systems_pre_launch.js --network localhost
npx hardhat run scripts/14_deployed_vault_strategy_role_setup.js --network localhost
npx hardhat run scripts/15_systems_launch.js --network localhost
