// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MatchMaking is Ownable {
    address private _gameContract;

    constructor(address gameContract) {
        _gameContract = gameContract;
    }

    modifier onlyGameContract() {
        require(_msgSender() == _gameContract, "Only GameContract Allowed");
        _;
    }

    function joinQueue() public virtual;

    function leaveQueue() public virtual;

    function evaluateMatches() public virtual;

    function confirmMatch() public virtual;

    function writeMatchResult() public onlyGameContract {}

    function alterRanking() public onlyGameContract {}

    function alterGameContract(address newGameAddress) public onlyOwner {
        _gameContract = newGameAddress;
    }
}
