// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/TemperatureOracle.sol";

contract Caller is Ownable {
  int256 private temperature;
  address private oracleAddress;
  TemperatureOracleInterface private oracleInstance;  
    
  uint8 private _decimals = 2;

  event TemperatureUpdated(int256 temperature, uint256 id, address oracleAddress);
  event OracleAddressUpdated(address oracleAddress);
  event ReceivedNewRequest(uint256 id);

  mapping(uint256 => bool) requests;

  constructor(address _oracleAddress) {
    oracleAddress = _oracleAddress;
    oracleInstance = TemperatureOracleInterface(_oracleAddress);
    emit OracleAddressUpdated(_oracleAddress);
  }

  /// @dev Only owner can update oracleAddress
  /// @param _oracleInstanceAddress New oracle address
  function setOracleInstanceAddress(address _oracleInstanceAddress) public onlyOwner {
    oracleAddress = _oracleInstanceAddress;
    oracleInstance = TemperatureOracleInterface(_oracleInstanceAddress);
    emit OracleAddressUpdated(_oracleInstanceAddress);
  }

  /// @notice Request to update temperature
  /// @dev Call is made to oracle to new request id
  function updateLatestTemperature() public {
    uint256 id = oracleInstance.getLatestTemperature();
    requests[id] = true;
    emit ReceivedNewRequest(id);
  }
  
  /// @notice Updates temperature
  /// @dev oracle call this function to update temperature
  /// @param _temperature New temperature
  /// @param _id requestId which was to be resolved
  function callback(int256 _temperature, uint256 _id) public onlyOracle {
    require(requests[_id] == true, "This request id is not in pending list");
    temperature = _temperature;
    delete requests[_id];
    emit TemperatureUpdated(temperature, _id, msg.sender);
  }

  /// @notice Retrieve latest temperature reported by oracle
  /// @dev dApp call this function to get the updated temperature
  function getTemperature() public view returns(int256) {
    return temperature;
  }
  
  /// @notice Retrieve the decimal places
  function decimals() external view returns (uint8) {
        return _decimals;
  }

  modifier onlyOracle {
    require(msg.sender == oracleAddress, "You are not authorized to call this function");
    _;
  }
}