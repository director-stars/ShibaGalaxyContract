// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

interface ManagerInterface {
    function battlefields(address _address) external view returns (bool);

    function evolvers(address _address) external view returns (bool);

    function markets(address _address) external view returns (bool);

    function farmOwners(address _address) external view returns (bool);

    function generation() external view returns (uint256);

    function priceShiba() external view returns (uint256);

    function feeMarketRatePercent() external view returns (uint256);

    function feeUpgradeGeneration() external view returns (uint256);

    function feeChangeTribe() external view returns (uint256);

    function feeMarketRate() external view returns (uint256);

    function feeEvolve() external view returns (uint256);

    function feeAddress() external view returns (address);

    function ownableMaxSize() external view returns (uint256);

    function referralRate() external view returns (uint256);

    function referralRatePercent() external view returns (uint256);

    function nftMaxSize() external view returns (uint256);

    function priceStone() external view returns (uint256);
}