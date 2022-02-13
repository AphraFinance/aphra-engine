#!/bin/zsh
set -ex
#function forge_build_to_mars{
#
## run forge build scrub files that dont bind properly
#rm -rf out/
#rm -rf build/
#mkdir build
#forge build
#rm -rf out/*.t.sol
#rm -rf out/USDV*.sol
#rm -rf out/test.sol
#rm -rf out/*Test*.sol
#rm -rf out/StrategyInterfaces.sol
#rm -rf out/Engine.sol
#rm -rf out/Registry.sol
#rm -rf out/IVaderMinter*.sol
#rm -rf out/VaderGateway.sol
#rm -rf out/Mock*.sol
#rm -rf out/Safe*.sol
#rm -rf out/Console.sol
#cp -r out/Auth.sol out/Authority.sol
#cp -r out/Gauge.sol out/GaugeFactory.sol
#cp -r out/Bribe.sol out/BribeFactory.sol
#cd out/
#
#for file in *.sol; do
#    sed 's/deployed_bytecode/deployedBytecode/' $file
#
#    mv -- "${file}/${file%%.sol}.json" "../build/${file%%.sol}.json"
#done
#cd ..
#yarn mars
#}
function build_to_hardhat_deploy(){

  rm -rf libBuild/
  rm -rf srcBuild/
  mkdir srcBuild
  cp -r src/ srcBuild/ || true
  rm -rf srcBuild/test
  cp -r lib/ libBuild/ || true

  # TODO: loop for all libs and then replace like below
  find libBuild/ -type f \( -iname "*.sol" ! -iname "*test*" ! -iname "*DSTestPlus*" \) -exec sed -i '' 's+"solmate/+"@rari-capital/solmate/src/+g' {} + || true
  find srcBuild/ -type f \( -iname "*.sol" ! -iname "*test*" ! -iname "*DSTestPlus*" \) -exec sed -i '' 's+"solmate/+"@rari-capital/solmate/src/+g' {} + || true


  npx hardhat compile
}
build_to_hardhat_deploy || true
