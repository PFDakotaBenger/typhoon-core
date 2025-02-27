// https://tornado.cash
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Tornado.sol";

interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract ETHTornado is Tornado {
  constructor(
    IVerifier _verifier,
    IHasher _hasher,
    uint256 _denomination,
    uint32 _merkleTreeHeight
  ) Tornado(_verifier, _hasher, _denomination, _merkleTreeHeight) {}
  
    address constant SANCTIONS_CONTRACT = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb;
    SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
    
  function _processDeposit() internal override {
    require(msg.value == denomination, "Please send `mixDenomination` ETH along with transaction");
  }

  function _processWithdraw(
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) internal override {
    // sanity checks
    bool isRecipientSanctioned = sanctionsList.isSanctioned(_recipient);
    bool isRelayerSanctioned = sanctionsList.isSanctioned(_recipient);


    require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
    require(_refund == 0, "Refund value is supposed to be zero for ETH instance");
    require(!isRecipientSanctioned, "This Recipient is Sanctioned");
    require(!isRelayerSanctioned, "This Relayer is Sanctioned");


    (bool success, ) = _recipient.call{ value: denomination - _fee }("");
    require(success, "payment to _recipient did not go thru");
    if (_fee > 0) {
      (success, ) = _relayer.call{ value: _fee }("");
      require(success, "payment to _relayer did not go thru");
    }
  }
}
