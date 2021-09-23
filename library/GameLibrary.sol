// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library GameLibrary {
    enum MatchResult {
        DRAW,
        PLAYER_A_WIN,
        PLAYER_B_WIN
    }

    /**
        Match against 2 players in a timestamp
        WIP Need to check if nonce is needed
    */
    struct Match {
        Player playerA;
        Player playerB;
        uint256 timestamp;
    }

    struct Player {
        address addr;
        uint256 nonce;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
