// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IMagicStoneNFT.sol";
// For test suite
contract LaunchPool is Ownable{
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    // event WithDraw(address account, uint256 time);
    // mapping (address => bool) public contributors;
    address public token;
    mapping (address => uint256) public tokenAmount;
    uint256 totalTokenAmount;
    uint256 cycle;
    uint256 lastDistributionTime;
    // uint256 public amount;
    IMagicStoneNFT magicStoneNFT;

    constructor(){
        token = address(0x1c3c2804aD0b710EeEe58AD84A719D4aA4df9e6C);
        // amount = 1250 * 1e18;
        magicStoneNFT = address(0xDCc1b7F2bA315BbA6A454a66097825e54527D368);
        cycle = 7;
    }

    // function setToken(address _token) public onlyOwner{
    //     token = _token;
    // }

    // function airDrop(address _address) public{
    //     require(contributors[_address], "not allowed");
    //     require(withdrawDate[_address] == 0, "already withdrawn");
    //     ERC20 erc20token = ERC20(token);
    //     erc20token.safeTransfer(_address, amount);
    //     withdrawDate[_address] = block.timestamp;
    //     emit WithDraw(_address, block.timestamp);
    // }

    function deposit(address _account, uint256 _amount) public {
        require(magicStoneNFT.balanceOf(_account), "MAGICSTONENFT: owner doesn't have stoneNFT");
        require(block.timestamp % (cycle * 24 * 60 * 60) < (5 * 24 * 60 * 60), "can't deposit token, wait for next cycle.")
        IERC20(token).safeTransferFrom(_account, address(this), _amount);
        tokenAmount[_account].add(_amount);
        totalTokenAmount.add(_amount);
    }

    function withdraw(address _account, uint256 _amount) public {
        require(tokenAmount[_account] >= _amount, "owner doesn't have enough token");
        require(block.timestamp % (cycle * 24 * 60 * 60) < (5 * 24 * 60 * 60), "can't withdraw token, wait for next cycle.")
        IERC20(token).safeTransfer(_account, _amount);
        tokenAmount[_account].sub(_amount);
        totalTokenAmount.sub(_amount);
    }

    function claim(address _account) public {

    }

}