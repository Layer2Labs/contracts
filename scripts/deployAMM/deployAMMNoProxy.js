const { ethers, upgrades } = require('hardhat');
const snx = require('synthetix-2.50.4-ovm');
const { artifacts, contract, web3 } = require('hardhat');
const { getTargetAddress, setTargetAddress } = require('../helpers');
const w3utils = require('web3-utils');

async function main() {

	let accounts = await ethers.getSigners();
	let owner = accounts[0];
	let networkObj = await ethers.provider.getNetwork();
	let network = networkObj.name;
	let priceFeedAddress, ProxyERC20sUSDaddress;

	if (network == 'homestead') {
		network = 'mainnet';
	}

	if (networkObj.chainId == 69) {
		networkObj.name = 'optimisticKovan';
		network = 'optimisticKovan';
	}
	if (networkObj.chainId == 10) {
		networkObj.name = 'optimisticEthereum';
		network = 'optimisticEthereum';
	}

	console.log('Owner is: ' + owner.address);
	console.log('Network:' + network);
	console.log('Network id:' + networkObj.chainId);

	const ThalesAMM = await ethers.getContractFactory('ThalesAMM');
	const ThalesAMMDeployed = await ThalesAMM.deploy();
	await ThalesAMMDeployed.deployed();

	setTargetAddress('ThalesAMMImplementation', network, ThalesAMMDeployed.address);


	try {
		await hre.run('verify:verify', {
			address: ThalesAMMDeployed.address,
		});
	} catch (e) {
		console.log(e);
	}

}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});

function delay(time) {
	return new Promise(function(resolve) {
		setTimeout(resolve, time);
	});
}
