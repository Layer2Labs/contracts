const path = require('path');
const { ethers, upgrades } = require('hardhat');
const { getImplementationAddress } = require('@openzeppelin/upgrades-core');


const { getTargetAddress, setTargetAddress } = require('../helpers');

async function main() {
	let accounts = await ethers.getSigners();
	let owner = accounts[0];
	let networkObj = await ethers.provider.getNetwork();
	let network = networkObj.name;
	let mainnetNetwork = 'mainnet';

	if (network == 'homestead') {
		console.log("Error L1 network used! Deploy only on L2 Optimism. \nTry using \'--network optimistic\'")
		return 0;
	}
	if (networkObj.chainId == 42) {
		console.log("Error L1 network used! Deploy only on L2 Optimism. \nTry using \'--network optimisticKovan\'")
		return 0;
	}
	if (networkObj.chainId == 69) {
		networkObj.name = 'optimisticKovan';
		network = 'optimisticKovan';
		mainnetNetwork = 'kovan';
	}
	if (networkObj.chainId == 10) {
		networkObj.name = 'optimistic';
		network = 'optimistic';
	}
	
    const ExoticTagsContract = await ethers.getContractFactory('ExoticPositionalTags');
	const ExoticMarketManagerAddress = getTargetAddress("ExoticMarketManager", network);
	const ExoticMarketManager = await ethers.getContractFactory('ExoticPositionalMarketManager');
    
    const ExoticTagsDeployed = await upgrades.deployProxy(ExoticTagsContract, [
        owner.address
	]);
	await ExoticTagsDeployed.deployed;
    
    console.log("ExoticPositionalTags Deployed on", ExoticTagsDeployed.address);
	setTargetAddress('ExoticPositionalTags', network, ExoticTagsDeployed.address);

	const ExoticTagsImplementation = await getImplementationAddress(
		ethers.provider,
		ExoticTagsDeployed.address
	);

	console.log('Implementation ExoticPositionalTags: ', ExoticTagsImplementation);
	setTargetAddress('ExoticPositionalTagsImplementation', network, ExoticTagsImplementation);
	
	const ExoticMarketManagerDeployed = await ExoticMarketManager.attach(ExoticMarketManagerAddress);
	await ExoticMarketManagerDeployed.setTagsAddress(ExoticTagsDeployed.address);
	console.log("ExoticTags address set in ExoticMarketManager");
	

    try {
		await hre.run('verify:verify', {
			address: ExoticTagsDeployed.address,
		});
	} catch (e) {
		console.log(e);
	}

    try {
		await hre.run('verify:verify', {
			address: ExoticTagsImplementation,
		});
	} catch (e) {
		console.log(e);
	}


}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

    
function delay(time) {
	return new Promise(function(resolve) {
		setTimeout(resolve, time);
	});
}