const { ethers } = require('hardhat');
const w3utils = require('web3-utils');
const snx = require('synthetix-2.50.4-ovm');
const { artifacts, contract, web3 } = require('hardhat');

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

	if (networkObj.chainId == 10) {
		network = 'optimistic';
	} else if (networkObj.chainId == 69) {
		network = 'optimisticKovan';
	}

	// We get the contract to deploy
	let TherundownConsumerContract = await ethers.getContractFactory('TherundownConsumer');
	const therundownConsumerContractDeployed = await TherundownConsumerContract.attach(
		'0x4281Fc17D2dEe2D5Ca67D6541c285D39ba6fb878'
	);
	await therundownConsumerContractDeployed.deployed();

	console.log(
		'therundownConsumerContractDeployed deployed to:',
		therundownConsumerContractDeployed.address
	);

	const date = new Date(Date.now() + 3600 * 1000 * 24);

	let timeInUnix = Math.floor(date.getTime() / 1000);

	let tx = await therundownConsumerContractDeployed.requestGames(
		toBytes32('9de17351dfa5439d83f5c2f3707ffa9e'),
		w3utils.toWei('0.1'),
		'create',
		4, //NBA
		timeInUnix
	);
	await tx.wait().then(e => {
		console.log('requestGames');
	});
}

main()
	.then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});
