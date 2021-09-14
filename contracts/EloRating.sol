// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./RatingSystem.sol";

contract EloRating is RatingSystem {
    uint256 public constant VICTORY = 10000;
    uint256 public constant DRAW = VICTORY / 2;
    // K Factor for Elo Rating
    uint256 public kFactor;

    event KFactorUpdate(uint256 newKFactor);
    event EloUpdate(address indexed player, uint256 elo);
    mapping(address => PlayerRating) playerElo;

    constructor(address addr) RatingSystem(addr) {}

    struct PlayerRating {
        uint256 elo;
        uint256 nonce;
        uint256 lastUpdatedRating;
    }

    /**
        Update k factor for Elo Rating
    */
    function updateKFactor(uint256 newKFactor) public onlyOwner {
        kFactor = newKFactor;
        emit KFactorUpdate(newKFactor);
    }

    function writeMatchResult(Match memory m, MatchResult result)
        public
        override
        onlyGameContract
    {
        bytes32 hash = hashToSignMatch(m);
        require(
            matches[hash].state == MatchState.RUNNING,
            "match isn't running"
        );
        // We save before the update to evict wrong calculation
        uint256 ratingA = getPlayerRating(m.player1);
        uint256 ratingB = getPlayerRating(m.player2);

        // Check for players score
        uint256 scorePlayer1 = 0;
        uint256 scorePlayer2 = 0;
        if (result == MatchResult.PLAYER1_WIN) {
            scorePlayer1 = VICTORY;
        } else if (result == MatchResult.PLAYER2_WIN) {
            scorePlayer2 = VICTORY;
        } else {
            scorePlayer1 = DRAW;
            scorePlayer2 = DRAW;
        }

        uint256 qA = 10**(ratingA / 400);
        uint256 qB = 10**(ratingB / 400);

        // Calculate the expected score for player 1
        uint256 expectedScore = (qA / (qA + qB)) * INVERSE_BASIS_POINT;
        calculateElo(m.player1, expectedScore, scorePlayer1);

        // Calculate the expected score for player 2
        expectedScore = (qB / (qA + qB)) * INVERSE_BASIS_POINT;
        calculateElo(m.player2, expectedScore, scorePlayer2);

        // Set the match to finished
        matches[hash].state = MatchState.FINISHED;
    }

    /**
        Calculate elo using initial formula
        WIP: It needs some testing how uint handles the decimal part of the formula
    */
    function calculateElo(
        address player,
        uint256 expectedScore,
        uint256 scoredPoints
    ) internal {
        uint256 ratingA = getPlayerRating(player);

        uint256 newElo = uint256(
            int256(ratingA) +
                ((int256(kFactor) *
                    (int256(scoredPoints) - int256(expectedScore))) /
                    int256(INVERSE_BASIS_POINT))
        );
        updatePlayerRating(player, newElo);
    }

    function createMatch(
        Match memory m,
        Sig memory p1sig,
        Sig memory p2sig
    ) public override {
        bytes32 hash = requireValidMatch(m, p1sig, p2sig);

        matches[hash].state = MatchState.RUNNING;
        // Update nonces WIP
        playerElo[m.player1].nonce++;
        playerElo[m.player2].nonce++;

        // Emit events
        emit MatchCreate(m.player1, m.player2, m.timestamp);
    }

    function updatePlayerRating(address p, uint256 newEloRating) internal {
        playerElo[p].elo = newEloRating;
        playerElo[p].lastUpdatedRating = block.timestamp;
        emit EloUpdate(p, newEloRating);
    }

    function getPlayerRating(address p) private returns (uint256 elo) {
        elo = playerElo[p].elo;
        if (elo == 0) elo = 1500;
    }
}
