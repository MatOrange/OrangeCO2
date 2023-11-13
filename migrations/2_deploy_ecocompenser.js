// 3_deploy_ecocompenser.js
const Ecocompensation = artifacts.require("Ecocompensation");

module.exports = function(deployer) {
  deployer.deploy(Ecocompensation);
};
