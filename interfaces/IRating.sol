// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/GameLibrary.sol";

interface IRating {
    
    function createMatch(
        GameLibrary.Match memory m,
        GameLibrary.Sig memory pAsig,
        GameLibrary.Sig memory pBsig
    ) external returns (bytes32 hash);

    function writeMatchResult(GameLibrary.Match memory m, GameLibrary.MatchResult result) external;
}
