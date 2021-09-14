// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IRating {
    enum MatchResult {
        DRAW,
        PLAYER1_WIN,
        PLAYER2_WIN
    }

    /**
        Match against 2 players in a timestamp
        WIP Need to check if nonce is needed
    */
    struct Match {
        address player1;
        address player2;
        uint256 timestamp;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function createMatch(
        Match memory m,
        Sig memory p1sig,
        Sig memory p2sig
    ) external;

    function writeMatchResult(Match memory m, MatchResult result) external;
}
