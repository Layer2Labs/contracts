const { ethers } = require('hardhat');
const w3utils = require('web3-utils');
const snx = require('synthetix-2.50.4-ovm');
const { artifacts, contract, web3 } = require('hardhat');

const {
	fastForward,
	toUnit,
	currentTime,
	multiplyDecimalRound,
	divideDecimalRound,
} = require('../../test/utils/index')();

const ZERO_ADDRESS = '0x' + '0'.repeat(40);

const { getTargetAddress, setTargetAddress } = require('../helpers');

const { toBytes32 } = require('../../index');

async function main() {
	let accounts = await ethers.getSigners();
	let owner = accounts[0];
	let networkObj = await ethers.provider.getNetwork();
	console.log(networkObj);
	let network = networkObj.name;
	if (network == 'homestead') {
		network = 'mainnet';
	}
	if (networkObj.chainId == 69) {
		networkObj.name = 'optimisticKovan';
		network = 'optimisticKovan';
	}
	if(networkObj.chainId == 10) {
		networkObj.name = "optimisticEthereum";
		network = 'optimisticEthereum'		
	}

	console.log('Account is:' + owner.address);
	console.log('Network name:' + network);

	const PositionalMarketManagerAddress = getTargetAddress('PositionalMarketManager', network);
	console.log('Found PositionalMarketManager at:' + PositionalMarketManagerAddress);
	

	const ZeroExAddress = getTargetAddress('ZeroEx', network);
	console.log('Found 0x at:' + ZeroExAddress);

	// const PositionalMarketFactoryAddress = getTargetAddress('PositionalMarketFactory', network);
	// console.log('Found PositionalMarketFactory at:' + PositionalMarketFactoryAddress);

	// let abi = ['function setPositionalMarketFactory(address _positionalMarketFactory) external'];
	// let contract = new ethers.Contract(PositionalMarketManagerAddress, abi, owner);

	// let setPositions = await contract.setPositionalMarketFactory(
	// 	PositionalMarketFactoryAddress,
	// 	{
	// 		from: owner.address,
	// 		gasLimit: 5000000
	// 	}
	// );
	// console.log(setPositions)
	// setPositions.wait().then(console.log('Done transfer! $$$$ >'));


	
	// 3. Deployment Position Market Factory
	let abi = ['function setZeroExAddress(address _zeroExAddress) public'];
	let contract = new ethers.Contract(PositionalMarketManagerAddress, abi, owner);
	let setZeroEx = await contract.setZeroExAddress(
			ZeroExAddress,
			{
				from: owner.address,
				gasLimit: 5000000
			}
		);
	console.log(setZeroEx)
	setZeroEx.wait().then(console.log('Done transfer! $$$$ >'));

}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

function delay(time) {
	return new Promise(function (resolve) {
		setTimeout(resolve, time);
	});
}
