// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./interface/Caller.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract TemperatureOracle is AccessControl {
  using SafeMath for uint256;
  address private owner;
  bytes32 public constant ORACLE_ROLE = 0x68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef1;

  uint private randNonce = 0;
  uint private modulus = 1000;
  uint16 public numOracles = 0;
  uint16 public threshold = 0;
  int16 private constant LOWEST_TEMPERATURE = -7000;
  int16 private constant HIGHEST_TEMPERATURE = 7000;
  
  uint8 private _decimals = 2;

  struct Response {
    address oracleAddress;
    address callerAddress;
    int256 temperature;
  }

  mapping(uint256 => bool) public pendingRequests;
  mapping(uint256 => Response[]) requestIdToResponse;
  mapping(uint256 => mapping(address => bool)) public requestReponded;

  event OracleAdded(address indexed oracleAddress);
  event OracleRemoved(address indexed oracleAddress);
  event ThresholdUpdated(uint16 newThreshold);
  event GetLatestTemperature(address callerAddress, uint id);
  event SetLatestTemperature(int256 temperature, address callerAddress, uint256 id);


  modifier onlyOwner() {
    require(owner == msg.sender, 'Caller is not owner');
    _;
  }
  
  constructor() {
    owner = msg.sender;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Grant oracle role to address
  /// @dev Only admin can give access to new oracle address
  /// @param _oracle address to grant access for ORACLE_ROLE
  function addOracle(address _oracle) public onlyOwner {
    require(!hasRole(ORACLE_ROLE, _oracle), "Oracle role already exists");
    numOracles++;
    grantRole(ORACLE_ROLE, _oracle);
    emit OracleAdded(_oracle);
  }
  
  /// @notice Revoke oracle role from address
  /// @dev Only admin can give revoke oracle role\
  /// @param _oracle address to revoke access for ORACLE_ROLE
  function removeOracle(address _oracle) public onlyOwner {
    require(hasRole(ORACLE_ROLE, _oracle), "Oracle role doesn't exist");
    numOracles--;
    revokeRole(ORACLE_ROLE, _oracle);
    emit OracleRemoved(_oracle);
  }

  /// @notice Update threshold of oracles to update temperature
  /// @dev Only admin can update threshold
  function updateThreshold(uint16 _newThreshold) public onlyOwner {
    threshold = _newThreshold;
    emit ThresholdUpdated(_newThreshold);
  }

  /// @notice Adds unique id to pending requests
  /// @dev Returns unique which is being added to pending requests
  /// @return id
  function getLatestTemperature() public returns(uint256) {
    randNonce++;
    uint256 id = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, randNonce))) % modulus;
    pendingRequests[id] = true;
    emit GetLatestTemperature(msg.sender, id);
    return id;
  }

  /// @notice Oracle sends response for id
  /// @dev Oracle submits temperature response for id
  /// @param _temperature temperature for id
  /// @param _callerAddress callerAddress contract
  /// @param _id requestId
  function setLatestTemperature(int16 _temperature, address _callerAddress ,uint256 _id) public {
    require(hasRole(ORACLE_ROLE, msg.sender), "Only oracle can set temperature");
    require(pendingRequests[_id], "This request id is not in pending list");
    require(!requestReponded[_id][msg.sender], "Oracle can only vote once");

    requestReponded[_id][msg.sender] = true;
    Response memory resp;
    resp = Response(msg.sender, _callerAddress, _temperature);
    requestIdToResponse[_id].push(resp);
    uint256 numResponses = requestIdToResponse[_id].length;
    
    if (numResponses == threshold) {
    	int256 totalTemperature = 0;
      int256 computedTemperature = 0;
      for (uint256 i = 0; i < numResponses; i++) {
      	if(requestIdToResponse[_id][i].temperature < HIGHEST_TEMPERATURE && requestIdToResponse[_id][i].temperature > LOWEST_TEMPERATURE) {
        	totalTemperature = computedTemperature + requestIdToResponse[_id][i].temperature;
        }
      }
      computedTemperature = totalTemperature / int256(numResponses);
      if(computedTemperature >= 0) {
      	if((totalTemperature % int256(numResponses)) > (int256(numResponses) / 2)) {
      		computedTemperature += 1; 
      	}
      } else {
      	if((totalTemperature % int256(numResponses)) < (int256(numResponses) / 2)) {
      		computedTemperature -= 1; 
      	}
      }
      CallerInterface callerInstance;
      callerInstance = CallerInterface(_callerAddress);
      callerInstance.callback(computedTemperature, _id);
      emit SetLatestTemperature(computedTemperature, _callerAddress, _id);
    }
  }
  
  /// @notice Retrieve the decimal places
  function decimals() external view returns (uint8) {
        return _decimals;
  }
}