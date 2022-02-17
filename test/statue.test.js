const { ethers, upgrades } = require('hardhat');
const assert = require("assert");

describe('SipherStatue', async () => {
	it('check deploy', async function () {
		[owner, account1, account2, account3] = await ethers.getSigners();
		const SipherStatueFactory = await ethers.getContractFactory('SipherStatue');
		SipherStatue = await SipherStatueFactory.connect(owner).deploy();
	});

	it('check mint and mintTo function', async function () {
		await SipherStatue.connect(owner).tokenRegistry("INU");
		await SipherStatue.connect(owner).tokenRegistry("NEKO");
		await SipherStatue.connect(owner).mint(1,2);
		await SipherStatue.connect(owner).mint(2,1);
		await SipherStatue.connect(owner).mintTo(account3.address, 2, 1);
		await SipherStatue.connect(owner).setNewURI("https://game.examplever2/api/item/{id}.json");
		owner_INU_balance = await SipherStatue.balanceOf(owner.address,2);
		owner_NEKO_balance = await SipherStatue.balanceOf(owner.address,1);
		account3_NEKO_balance = await SipherStatue.balanceOf(account3.address,2);
		assert.equal(owner_INU_balance, 1);
		assert.equal(owner_NEKO_balance, 2);
		assert.equal(account3_NEKO_balance, 1);
	});

	it('Avoid adding duplicate token name (already added before)', async function () {
		try {
			await SipherStatue.connect(owner).tokenRegistry("INU");
			assert(false);
		} catch (err) {
			assert(err);
		}
	});


	it('check transfer', async function () {
		await SipherStatue.connect(owner).setApprovalForAll(SipherStatue.address, true);
		await SipherStatue.safeTransferFrom(owner.address, account1.address, 1, 1, []);
		owner_NEKO_balance_ = await SipherStatue.balanceOf(owner.address, 1);
		account1_NEKO_balance_ = await SipherStatue.balanceOf(account1.address,1);
		assert.equal(account1_NEKO_balance_, 1);
	});

	it('check after claim, user cannot do transfer if exceed the balance of their token', async function () {
		claim_transact = await SipherStatue.connect(account1).claimStatue(1, 1);
		try {
			await SipherStatue.connect(account1).safeTransferFrom(account1.address, account2.address, 1, 1, []);
			assert(false);
		} catch (err) {
			assert(err);
		}
		try {
			await SipherStatue.connect(account1).safeBatchTransferFrom(account1.address, account2.address, [1], [1], []);
			assert(false);
		} catch (err) {
			assert(err);
		}
	});

	it('check after claim a token, user cannot claim again if exceed the balance of their token', async function () {
		try {
			await SipherStatue.connect(account1).claimStatue(1, 1);
			assert(false);
		} catch (err) {
			assert(err);
		}
	});

	it('check lock user by admin', async function () {
		await SipherStatue.safeTransferFrom(owner.address, account1.address, 2, 1, []);
		lock_transact = await SipherStatue.connect(owner).adminLockUser(account1.address);
		try {
			await SipherStatue.connect(account1).setApprovalForAll(SipherStatue.address, true);
			assert(false);
		} catch (err) {
			assert(err);
		}
		try {
			await SipherStatue.connect(account1).safeTransferFrom(account1.address, account2.address, 2, 1, []);
			assert(false);
		} catch (err) {
			assert(err);
		}
		try {
			await SipherStatue.connect(account1).safeBatchTransferFrom(account1.address, account2.address, [2], [1], []);
			assert(false);
		} catch (err) {
			assert(err);
		}
		// const receipt = await lock_transact.wait();
		// console.log(receipt.events)
	});

	it('check unlocked user by admin', async function () {
		unlock_transact = await SipherStatue.connect(owner).unLockedUser(account1.address);
		await SipherStatue.connect(account1).setApprovalForAll(SipherStatue.address, true);
		assert(true);
		// const receipt = await unlock_transact.wait();
		// console.log(receipt.events)
	});

});