// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IMagicStoneNFT.sol";
// For test suite
contract LaunchPool is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public token;
    mapping(uint256 => mapping(address => uint256)) public tokenAmount;
    mapping(uint256 => uint256) public totalTokenAmount;
    mapping(uint256 => uint256) public distributeAmount;
    mapping(uint256 => uint256) public oldTokenAmount;
    uint256 public round;
    uint256 public startTime;
    uint256 public depositTime;
    uint256 public checkTime;

    IMagicStoneNFT public magicStoneNFT;

    constructor(){
        token = address(0x7420d2Bc1f8efB491D67Ee860DF1D35fe49ffb8C);
        magicStoneNFT = IMagicStoneNFT(0xC6E6BE483bC1048c05DFE3d7Ed03455BF067b348);
        // token = address(0x1c3c2804aD0b710EeEe58AD84A719D4aA4df9e6C);
        // magicStoneNFT = IMagicStoneNFT(0xDCc1b7F2bA315BbA6A454a66097825e54527D368);
        round = 1;
        depositTime = 5 * 24 * 3600;
        checkTime = 2 * 24 * 3600;
    }

    receive() external payable {}

    function startRound(uint256 _amount) public onlyOwner {
        distributeAmount[round] = _amount;
        startTime = block.timestamp;
    }

    function deposit(address _account, uint256 _amount) public {
        require(magicStoneNFT.balanceOf(_account) > 0, "account doesn't have magic stone");
        require(block.timestamp < (startTime + depositTime), "can't deposit token, wait for next cycle.");
        require(startTime > 0, "not started");
        IERC20(token).safeTransferFrom(_account, address(this), _amount);
        tokenAmount[round][_account] = tokenAmount[round][_account].add(_amount);
        totalTokenAmount[round] = totalTokenAmount[round].add(_amount);
    }

    function withdrawTokenForCurrentRound(address _account) public {
        require(tokenAmount[round][_account] > 0, "not enough token");
        require(block.timestamp < (startTime + depositTime), "can't withdraw token, wait for next cycle.");
        IERC20(token).safeTransfer(_account, tokenAmount[round][_account]);
        totalTokenAmount[round] = totalTokenAmount[round].sub(tokenAmount[round][_account]);
        tokenAmount[round][_account] = 0;
        
    }

    function claimAndWithdrawForOldRound(address _account) public {
        uint256 i;
        uint256 _oldTokenAmount = getOldTokenAmount(_account);
        uint256 _oldClaimAmount = getOldClaimAmount(_account);
        require(_oldTokenAmount > 0, "owner doesn't have token for old round");
        IERC20(token).safeTransfer(_account, _oldTokenAmount);
        (bool success,) = payable(_account).call{value: _oldClaimAmount}("");
        for(i = 1; i < round; i ++){
            if(tokenAmount[i][_account] > 0)
                tokenAmount[i][_account] = 0;
        }
    }

    function getDepositedAmount(address _account) public view returns(uint256){
        return tokenAmount[round][_account];
    }

    function getOldTokenAmount(address _account) public view returns(uint256){
        uint256 i;
        uint256 _oldTokenAmount = 0;
        for(i = 1; i < round; i ++){
            _oldTokenAmount += tokenAmount[i][_account];
        }
        return _oldTokenAmount;
    }

    function getOldClaimAmount(address _account) public view returns(uint256){
        uint256 i;
        uint256 _oldClaimAmount = 0;
        for(i = 1; i < round; i ++){
            if(totalTokenAmount[i] != 0)
                _oldClaimAmount += tokenAmount[i][_account].mul(distributeAmount[i]).div(totalTokenAmount[i]);
        }
        return _oldClaimAmount;
    }

    function endRound() public onlyOwner {
        require(startTime != 0, "round already ended");
        round ++;
        startTime = 0;
    }

    function updatedCurrentDistributeAmount(uint256 _amount) public onlyOwner {
        distributeAmount[round] = _amount;
    }

    function updateDepositTime(uint256 _depositTime) public onlyOwner {
        depositTime = _depositTime;
    }

    function updateCheckTime(uint256 _checkTime) public onlyOwner {
        checkTime = _checkTime;
    }

    function withdraw(address _account, uint256 _value) public onlyOwner {
        (bool success,) = payable(_account).call{value: _value}("");
    }
}