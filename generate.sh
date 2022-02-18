#!/bin/zsh
set -ex
function build_to_hardhat_deploy(){

  rm -rf libBuild/
  rm -rf srcBuild/
  mkdir srcBuild
  cp -r src/ srcBuild/ || true
  rm -rf srcBuild/test
  cp -r lib/ libBuild/ || true

  # TODO: loop for all libs and then replace like below
  find libBuild/ -type f \( -iname "*.sol" ! -iname "*test*" ! -iname "*DSTestPlus*" \) -exec sed -i '' 's+AGPL-3.0-only+GNU AGPLv3+g' {} + || true
  find libBuild/ -type f \( -iname "*.sol" ! -iname "*test*" ! -iname "*DSTestPlus*" \) -exec sed -i '' 's+AGPL-3.0-only+GNU AGPLv3+g' {} + || true
  find srcBuild/ -type f \( -iname "*.sol" ! -iname "*test*" ! -iname "*DSTestPlus*" \) -exec sed -i '' 's+"solmate/+"@rari-capital/solmate/src/+g' {} + || true
  find srcBuild/ -type f \( -iname "*.sol" ! -iname "*test*" ! -iname "*DSTestPlus*" \) -exec sed -i '' 's+"solmate/+"@rari-capital/solmate/src/+g' {} + || true


  npx hardhat compile
}
build_to_hardhat_deploy || true
