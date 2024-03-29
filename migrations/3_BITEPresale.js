const BN = require('bn.js');

require('dotenv').config();

const {
    BITE_DECIMALS,
    BTC,
    BTC_DECIMALS
} = process.env;

const BITE = artifacts.require("BITE");
const BITEPresale = artifacts.require("BITEPresale");

const debug = "true";

const ZERO = new BN(0);
const ONE = new BN(1);
const TWO = new BN(2);
const THREE = new BN(3);

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

module.exports = async function (deployer, network) {
    if (network == "test" || network == "development")
        return;
    let BITEInst = await BITE.deployed();
    await deployer.deploy(
        BITEPresale, BITEInst.address, BITE_DECIMALS, BTC, BTC_DECIMALS
    );
    let BITEPresaleInst = await BITEPresale.deployed();
    console.log("BITEPresale =", BITEPresaleInst.address);
};