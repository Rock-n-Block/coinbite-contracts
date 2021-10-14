const BN = require('bn.js');

require('dotenv').config();

const DeflationaryAutoLPToken = artifacts.require("BITE");

const DEFAULT_NAME = "Coinbite";
const DEFAULT_SYMBOL = "BITE";
const DEFAULT_DECIMALS = 9;
const DEFAULT_TOTAL_AMOUNT = new BN("1000000000000").mul(new BN(10).pow(new BN(DEFAULT_DECIMALS)));


const DEFAULT_TAXFEE = 2;
const DEFAULT_LIQFEE = 5;
const DEFAULT_BURNFEE = 0;
const DEFAULT_MAXTX = new BN("1000000000000000").mul(new BN(10).pow(new BN(DEFAULT_DECIMALS))); // max transaction amount 5 * 10**21
const DEFAULT_MIN_TOK_FOR_LIQ = new BN("1000").mul(new BN(10).pow(new BN(DEFAULT_DECIMALS))); // min locked in contract amount for LP 5 * 10**20
const IS_LP_ENABLED_DEFAULT = true;

const KOVAN_UNISWAP_ROUTER = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const BSC_TESTNET_ROUTER = "0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0";
const ROUTER = BSC_TESTNET_ROUTER;


module.exports = async function (deployer, network) {
    // if (network == "test" || network == "development")
    //     return;

    await deployer.deploy(
        DeflationaryAutoLPToken, 
        DEFAULT_NAME, 
        DEFAULT_SYMBOL, 
        DEFAULT_TOTAL_AMOUNT, 
        DEFAULT_DECIMALS, 
        DEFAULT_TAXFEE, 
        DEFAULT_LIQFEE, 
        DEFAULT_MAXTX,
        DEFAULT_MIN_TOK_FOR_LIQ, 
        IS_LP_ENABLED_DEFAULT, 
        ROUTER
    );


    let DeflationaryAutoLPTokenInst = await DeflationaryAutoLPToken.deployed();
    console.log("Token = ", DeflationaryAutoLPTokenInst.address);
    console.log("Contract name = ", DEFAULT_SYMBOL);
};