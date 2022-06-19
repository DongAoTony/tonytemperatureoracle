
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface CallerInterface {
  function callback(int256 temperature, uint256 id) external;
}