const { ethers } = require('hardhat');
const w3utils = require('web3-utils');
const snx = require('synthetix-2.50.4-ovm');
const { artifacts, contract, web3 } = require('hardhat');
const { setTargetAddress, getTargetAddress } = require('../helpers');

const { getImplementationAddress } = require('@openzeppelin/upgrades-core');

const { toBN } = web3.utils;

const { toBytes32 } = require('../../index');

async function main() {
	let accounts = await ethers.getSigners();
	let owner = accounts[0];
	let networkObj = await ethers.provider.getNetwork();
	let network = networkObj.name;
	if (network == 'homestead') {
		network = 'mainnet';
	}

	console.log('Account is:' + owner.address);
	console.log('Network name:' + networkObj.name);

	if (network === 'unknown') {
		network = 'localhost';
	}

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

	if (networkObj.chainId == 80001) {
		networkObj.name = 'polygonMumbai';
		network = 'polygonMumbai';
	}

	if (networkObj.chainId == 137) {
		networkObj.name = 'polygon';
		network = 'polygon';
	}

	/* ========== PROPERTIES FOR INITIALIZE ========== */

	const exoticManager = await ethers.getContractFactory('ExoticPositionalMarketManager');
	let exoticManagerAddress = getTargetAddress('ExoticMarketManager', network);

	console.log('ExoticMarketManager address: ', exoticManagerAddress);

	const chainlink = require(`./chainlink/${network}.json`);

	console.log('LINK address:', chainlink['LINK']);
	console.log('ORACLE address:', chainlink['ORACLE']);

	// NBA: 4
	// EPL: 11
	// UEFA Champions League: 16
	const allowedSports = [4, 11, 16];

	const twoPositionSports = [4];
	const fixedPrice = w3utils.toWei('10');
	const withdrawalAllowed = true;

	/* ========== DEPLOY CONTRACT ========== */

	// queue

	console.log('Starting...');

	const GamesQueue = await ethers.getContractFactory('GamesQueue');

	const gamesQueue = await upgrades.deployProxy(GamesQueue, [
		owner.address
	]);

	await gamesQueue.deployed();

	console.log('GamesQueue deployed to:', gamesQueue.address);
	setTargetAddress('GamesQueue', network, gamesQueue.address);

	const implementationQueue = await getImplementationAddress(ethers.provider, gamesQueue.address);
	console.log('GamesQueueImplementation: ', implementationQueue);
	setTargetAddress('GamesQueueImplementation', network, implementationQueue);

	// consumer

	let TherundownConsumer = await ethers.getContractFactory('TherundownConsumer');
	const therundown = await upgrades.deployProxy(TherundownConsumer, [
		owner.address,
		allowedSports,
		exoticManagerAddress,
		twoPositionSports,
		fixedPrice,
		withdrawalAllowed,
		gamesQueue.address,
	]);

	await therundown.deployed();

	console.log('TherundownConsumer deployed to:', therundown.address);
	setTargetAddress('TherundownConsumer', network, therundown.address);

	const implementation = await getImplementationAddress(ethers.provider, therundown.address);
	console.log('TherundownConsumerImplementation: ', implementation);
	setTargetAddress('TherundownConsumerImplementation', network, implementation);

	await therundown.setQueueAddress(gamesQueue.address);
	console.log("GamesQueue address set in TherundownConsumer");

	await gamesQueue.setConsumerAddress(therundown.address);
	console.log("TherundownConsumer address set in GamesQueue");

	await hre.run('verify:verify', {
		address: implementationQueue
	})

	await hre.run('verify:verify', {
		address: implementation,
	});
}

function delay(time) {
	return new Promise(function(resolve) {
		setTimeout(resolve, time);
	});
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});
