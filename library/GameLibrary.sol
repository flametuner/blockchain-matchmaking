// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

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
        address playerA;
        uint256 nonceA;
        address playerB;
        uint256 nonceB;
        uint256 timestamp;
    }

    // struct Player {
    //     address addr;
    //     uint256 nonce;
    // }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _requireValidMatch(
        GameLibrary.Match memory m,
        GameLibrary.Sig memory sigpA,
        GameLibrary.Sig memory sigpB
    ) internal pure returns (bytes32 hash) {
        require(
            _validateMatch(m, hash = _hashToSignMatch(m), sigpA, sigpB),
            "invalid match"
        );
    }

    function _validateMatch(
        GameLibrary.Match memory m,
        bytes32 hash,
        GameLibrary.Sig memory sigpA,
        GameLibrary.Sig memory sigpB
    ) public pure returns (bool) {
        return
            ecrecover(hash, sigpA.v, sigpA.r, sigpA.s) == m.playerA &&
            ecrecover(hash, sigpB.v, sigpB.r, sigpB.s) == m.playerB;
    }

    function _ecrecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(hash, v, r, s);
    }

    function validateMatch(
        address pA,
        uint256 nonceA,
        address pB,
        uint256 nonceB,
        uint256 timestamp,
        uint8 vA,
        bytes32 rA,
        bytes32 sA,
        uint8 vB,
        bytes32 rB,
        bytes32 sB
    ) public pure returns (bool) {
        GameLibrary.Match memory m = GameLibrary.Match(
            pA,
            nonceA,
            pB,
            nonceB,
            timestamp
        );
        return
            _validateMatch(
                m,
                _hashToSignMatch(m),
                GameLibrary.Sig(vA, rA, sA),
                GameLibrary.Sig(vB, rB, sB)
            );
    }

    function _hashToSignMatch(GameLibrary.Match memory m)
        internal
        pure
        returns (bytes32)
    {
        return hashToSign(_hashMatch(m));
    }

    function hashMatch(
        address pA,
        uint256 nonceA,
        address pB,
        uint256 nonceB,
        uint256 timestamp
    ) public pure returns (bytes32) {
        return _hashMatch(GameLibrary.Match(pA, nonceA, pB, nonceB, timestamp));
    }

    function _hashMatch(GameLibrary.Match memory m)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    m.playerA,
                    m.nonceA,
                    m.playerB,
                    m.nonceB,
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
