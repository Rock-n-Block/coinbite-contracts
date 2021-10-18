// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BITEPresale is AccessControl, ReentrancyGuard {

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    address public immutable BITE;
    uint256 private immutable BITE_DECIMALS;
    address public immutable BTC;
    uint256 private immutable BTC_DECIMALS;

    uint256 public constant PRICE = 10000000000000;
    uint256 public immutable SOFT_CAP;
    uint256 public firstTwoHundred = 200;
    uint256 public tokenSold;
    uint256 public endTime;
    mapping (address => bool) firstUsers;

    mapping (address => uint256[3]) public amounts;
    uint256[3] private refundable;

    modifier afterStartAndBeforeEnd() {
        require(endTime > block.timestamp, "Already ended or not started");
        _;
    }

    constructor(address _BITE, uint256 _BITE_DECIMALS, address _BTC, uint256 _BTC_DECIMALS) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _msgSender());
        BITE = _BITE;
        BITE_DECIMALS = _BITE_DECIMALS;
        SOFT_CAP = 1000000000 * (10 ** _BITE_DECIMALS);
        BTC = _BTC;
        BTC_DECIMALS = _BTC_DECIMALS;
    }

    function start() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(endTime == 0, "Already started");
        endTime = block.timestamp + 3600;
    }

    function increaseEndTime(uint256 toIncrease) external onlyRole(DEFAULT_ADMIN_ROLE) afterStartAndBeforeEnd {
        endTime = endTime + toIncrease;
    }

    function buyForETH() external payable afterStartAndBeforeEnd nonReentrant {
        require(msg.value >= 100000000000000000, "Cannot pay less then 0.1 ETH");
        uint256 amount = (msg.value * (10 ** BITE_DECIMALS)) / PRICE;
        if (firstTwoHundred > 0 && !firstUsers[_msgSender()]) {
            amount += (amount * 20) / 100;
            firstUsers[_msgSender()] = true;
            firstTwoHundred--;
        }
        require(amount <= (IERC20(BITE).balanceOf(address(this)) - refundable[0]), "Cannot buy this much");
        tokenSold += amount;
        if (tokenSold < SOFT_CAP) {
            amounts[_msgSender()][0] += amount;
            refundable[0] += amount;
            amounts[_msgSender()][1] += msg.value;
            refundable[1] += msg.value;
        }
        else {
            require(IERC20(BITE).transfer(_msgSender(), amount));
        }
    }

    function buyForBTC(uint256 amountToPay, uint256 amountToReceive, uint256 deadline, bytes calldata signature) external afterStartAndBeforeEnd nonReentrant {
        require(hasRole(SIGNER_ROLE, ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(amountToPay, amountToReceive, deadline))), signature)), "Invalid signature");
        require(deadline >= block.timestamp, "Signature deadline passed");
        require(amountToPay > 0 && amountToReceive >= 10000 * (10 ** BITE_DECIMALS), "Cannot pay zero or receive less than 10000 BITE");
        require(amountToReceive <= (IERC20(BITE).balanceOf(address(this)) - refundable[0]), "Cannot buy this much");
        require(IERC20(BTC).transferFrom(_msgSender(), address(this), amountToPay));
        if (firstTwoHundred > 0 && !firstUsers[_msgSender()]) {
            amountToReceive += (amountToReceive * 20) / 100;
            firstUsers[_msgSender()] = true;
            firstTwoHundred--;
        }
        require(amountToReceive <= (IERC20(BITE).balanceOf(address(this)) - refundable[0]), "Cannot buy this much");
        tokenSold += amountToReceive;
        if (tokenSold < SOFT_CAP) {
            amounts[_msgSender()][0] += amountToReceive;
            refundable[0] += amountToReceive;
            amounts[_msgSender()][2] += amountToPay;
            refundable[2] += amountToPay;
        }
        else {
            require(IERC20(BITE).transfer(_msgSender(), amountToReceive));
        }
    }

    function redeem() external nonReentrant {
        require(IERC20(BITE).transfer(_msgSender(), amounts[_msgSender()][0]));
        for (uint256 i; i < 3; i++) {
            refundable[i] -= amounts[_msgSender()][i];
        }
        delete amounts[_msgSender()];
    }

    function refund() external nonReentrant {
        require(block.timestamp > endTime, "Not ended yet");
        require(tokenSold < SOFT_CAP, "Soft cap is reached");
        for (uint256 i; i < 3; i++) {
            uint256 toRefund = amounts[_msgSender()][i];
            if (toRefund > 0) {
                if (i == 0) {
                    tokenSold -= toRefund;
                }
                else if (i == 1) {
                    payable(_msgSender()).transfer(toRefund);
                }
                else {
                    require(IERC20(BTC).transfer(_msgSender(), toRefund));
                }
            }
            refundable[i] -= toRefund;
        }
        delete amounts[_msgSender()];
    }

    function getToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        if (token == BITE) {
            require(block.timestamp > endTime, "Not ended yet");
            IERC20 IToken = IERC20(token);
            require(IToken.transfer(_msgSender(), (IToken.balanceOf(address(this)) - refundable[0])));
        }
        else if (token == BTC) {
            IERC20 IToken = IERC20(token);
            uint256 toGet = IToken.balanceOf(address(this));
            if (tokenSold < SOFT_CAP) {
                toGet -= refundable[2];
            }
            if (toGet > 0) {
                require(IToken.transfer(_msgSender(), toGet));
            }
        }
        else if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            uint256 toGet = address(this).balance;
            if (tokenSold < SOFT_CAP) {
                toGet -= refundable[1];
            }
            if (toGet > 0) {
                payable(_msgSender()).transfer(toGet);
            }
        }
        else {
            IERC20 IToken = IERC20(token);
            require(IToken.transfer(_msgSender(), IToken.balanceOf(address(this))));
        }
    }
}