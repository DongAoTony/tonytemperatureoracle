// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface TemperatureOracleInterface {
  function getLatestTemperature() external returns(uint256);
}