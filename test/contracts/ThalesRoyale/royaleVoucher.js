'use strict';

const { artifacts, contract, web3 } = require('hardhat');
const { toBN } = web3.utils;

const { assert, addSnapshotBeforeRestoreAfterEach } = require('../../utils/common');

const { toBytes32 } = require('../../../index');

var ethers2 = require('ethers');
var crypto = require('crypto');

const SECOND = 1000;
const HOUR = 3600;
const DAY = 86400;
const WEEK = 604800;
const YEAR = 31556926;

const {
	toUnit
} = require('../../utils')();

const {
	onlyGivenAddressCanInvoke,
	convertToDecimals,
	encodeCall,
	assertRevert,
} = require('../../utils/helpers');

contract('ThalesRoyalePass', accounts => {
	const [first, owner, second, third, fourth] = accounts;
	let ThalesDeployed;
	let thales;
	let ThalesRoyalePass;
	let ThalesRoyaleDeployed;
	let ThalesRoyalePassDeployed;
	let voucher;
	const price = toUnit(30);
	const priceDouble = toUnit(60);
	const priceUnder = toUnit(20);
	const priceUpper = toUnit(200);
	const uri = 'http://my-json-server.typicode.com/abcoathup/samplenft/tokens/0';

	beforeEach(async () => {

        let ThalesRoyale = artifacts.require('TestThalesRoyale');
		ThalesRoyaleDeployed = await ThalesRoyale.new({ from: owner });
		let Thales = artifacts.require('Thales');
		ThalesDeployed = await Thales.new({ from: owner });

		ThalesRoyalePass = artifacts.require('ThalesRoyalePass');

		voucher = await ThalesRoyalePass.new(
			ThalesDeployed.address,
			uri,
			ThalesRoyaleDeployed.address
		);

		await ThalesRoyaleDeployed.setBuyInAmount(price);

		await ThalesDeployed.transfer(voucher.address, price, { from: owner });
		await ThalesDeployed.approve(voucher.address, price, { from: owner });

		await ThalesDeployed.transfer(first, price, { from: owner });
		await ThalesDeployed.approve(voucher.address, price, { from: first });

		await ThalesDeployed.transfer(second, price, { from: owner });
		await ThalesDeployed.approve(voucher.address, price, { from: second });

	});

	describe('Thales royale voucher', () => {
		it('Init checking', async () => {
			assert.bnEqual(toUnit(30), await ThalesRoyaleDeployed.getBuyInAmount());
			assert.bnEqual("Thales Royale Pass", await voucher.name());
			assert.bnEqual("TRP", await voucher.symbol());

		});

		it('Minting voucher', async () => {

			const id = 1;

			await voucher.mint(first);

			await expect(voucher.mint(third)).to.be.revertedWith('No enough sUSD');

			assert.bnEqual(id, await voucher.balanceOf(first));
			assert.equal(first, await voucher.ownerOf(id));

			await voucher.safeTransferFrom(first, second, id);

			assert.equal(second, await voucher.ownerOf(id));

			assert.bnEqual(price, await voucher.pricePaidForPass(id));

		});

		it('Top Up', async () => {

			const id_1 = 1;

			await voucher.mint(first);

			assert.bnEqual(1, await voucher.balanceOf(first));
			assert.equal(first, await voucher.ownerOf(id_1));
			assert.bnEqual(price, await voucher.pricePaidForPass(id_1));

			await voucher.safeTransferFrom(first, second, id_1);

			assert.equal(second, await voucher.ownerOf(id_1));

			await voucher.topUp(id_1, price, {from: second});

			assert.bnEqual(priceDouble, await voucher.pricePaidForPass(id_1));

		});

		it('Burning voucher', async () => {

			const id_1 = 1;
			const id_2 = 2;

			await voucher.mint(first);

			assert.bnEqual(1, await voucher.balanceOf(first));
			assert.equal(first, await voucher.ownerOf(id_1));
			assert.bnEqual(price, await voucher.pricePaidForPass(id_1));

			await voucher.safeTransferFrom(first, second, id_1);

			assert.equal(second, await voucher.ownerOf(id_1));

			await expect(voucher.burnWithTransfer(first, id_1, { from: first })).to.be.revertedWith('Sender must be thales royale contract');
			/*await ThalesRoyaleDeployed.setBuyInAmount(priceDouble);
			await expect(voucher.burnWithTransfer(first, id_1, { from: ThalesRoyaleDeployed.address })).to.be.revertedWith('Not enough sUSD allocated in the pass');
			await expect(voucher.burnWithTransfer(first, id_2, { from: ThalesRoyaleDeployed.address })).to.be.revertedWith('Not existing pass');

			await voucher.burnWithTransfer(second, id_1, { from: second });
			await expect(voucher.burnWithTransfer(second, id_1, { from: ThalesRoyaleDeployed.address })).to.be.revertedWith('Not existing pass');

			await ThalesDeployed.transfer(voucher.address, price, { from: owner });
			await ThalesDeployed.approve(voucher.address, price, { from: owner });

			await ThalesDeployed.transfer(first, price, { from: owner });
			await ThalesDeployed.approve(voucher.address, price, { from: first });

			await voucher.mint(second);

			assert.bnEqual(1, await voucher.balanceOf(second));
			assert.equal(second, await voucher.ownerOf(id_2));
			assert.bnEqual(price, await voucher.pricePaidForPass(id_2));

			await expect(voucher.burnWithTransfer(first, id_2, { from: ThalesRoyaleDeployed.address })).to.be.revertedWith('Must be owner or approver');
			await voucher.approve(first, id_2, { from: second });

			await voucher.burnWithTransfer(first, id_2, { from: ThalesRoyaleDeployed.address });
			await expect(voucher.burnWithTransfer(second, id_2, { from: ThalesRoyaleDeployed.address })).to.be.revertedWith('Not existing pass');*/

		});
	});
});