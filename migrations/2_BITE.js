const BN = require('bn.js');

require('dotenv').config();

const {
    BITE_OWNER,
    BITE_BENEFICIARY,
    BITE_BENEFICIARY_PERCENT,
    DEPLOYER_ADDRESS
} = process.env;

const DeflationaryAutoLPToken = artifacts.require("BITE");

const DEFAULT_NAME = "Coinbite";
const DEFAULT_SYMBOL = "BITE";
const DEFAULT_DECIMALS = 9;
const DEFAULT_TOTAL_AMOUNT = new BN("1000000000000").mul(new BN(10).pow(new BN(DEFAULT_DECIMALS)));


const DEFAULT_TAXFEE = 2;
const DEFAULT_LIQFEE = 5;
const DEFAULT_BURNFEE = 0;
const DEFAULT_MAXTX = new BN("1000000000000000").mul(new BN(10).pow(new BN(DEFAULT_DECIMALS)));
const DEFAULT_MIN_TOK_FOR_LIQ = new BN("1000").mul(new BN(10).pow(new BN(DEFAULT_DECIMALS)));
const IS_LP_ENABLED_DEFAULT = true;

const KOVAN_UNISWAP_ROUTER = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const BSC_TESTNET_ROUTER = "0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0";
const BSC_MAINNET_ROUTER = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
const ROUTER = BSC_MAINNET_ROUTER;


module.exports = async function (deployer, network) {
    if (network == "test" || network == "development")
        return;

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


    let BITEInst = await DeflationaryAutoLPToken.deployed();
    console.log("Token = ", BITEInst.address);

    await BITEInst.setLiquidityOwner(BITE_OWNER);

    await BITEInst.setFeeBeneficiary(BITE_BENEFICIARY);
    await BITEInst.setToAddressFee(BITE_BENEFICIARY_PERCENT);

    await BITEInst.transfer(BITE_OWNER, DEFAULT_TOTAL_AMOUNT);

    await BITEInst.includeInFee(DEPLOYER_ADDRESS);
    await BITEInst.transferOwnership(BITE_OWNER);
};