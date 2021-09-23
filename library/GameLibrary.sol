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

    function requireValidMatch(
        GameLibrary.Match memory m,
        GameLibrary.Sig memory sigpA,
        GameLibrary.Sig memory sigpB
    ) internal pure returns (bytes32 hash) {
        require(
            validateMatch(m, hash = hashToSignMatch(m), sigpA, sigpB),
            "invalid match"
        );
    }

    function validateMatch(
        GameLibrary.Match memory m,
        bytes32 hash,
        GameLibrary.Sig memory sigpA,
        GameLibrary.Sig memory sigpB
    ) public pure returns (bool) {
        return
            ecrecover(hash, sigpA.v, sigpA.r, sigpA.s) == m.playerA.addr &&
            ecrecover(hash, sigpB.v, sigpB.r, sigpB.s) == m.playerB.addr;
    }

    function hashToSignMatch(GameLibrary.Match memory m)
        internal
        pure
        returns (bytes32)
    {
        return hashToSign(hashMatch(m));
    }

    function hashMatch(GameLibrary.Match memory m)
        public
        pure
        returns (bytes32 hash)
    {
        hash = keccak256(
            abi.encodePacked(
                m.playerA.addr,
                m.playerA.nonce,
                m.playerB.addr,
                m.playerB.nonce,
                m.timestamp
            )
        );
    }

    function hashToSign(bytes32 hash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}
