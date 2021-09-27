// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./RatingSystem.sol";

contract EloRating is RatingSystem {
    int256 public constant VICTORY = int256(INVERSE_BASIS_POINT);
    int256 public constant DRAW = VICTORY / 2;
    // K Factor for Elo Rating
    int256 public constant kFactor = 20;

    // event KFactorUpdate(uint256 newKFactor);
    event EloUpdate(address indexed player, int256 elo);

    event EloChange(address indexed player, int256 elo);
    mapping(address => PlayerRating) playerElo;

    constructor(address addr) RatingSystem(addr) {}

    struct PlayerRating {
        int256 elo;
        // uint256 nonce;
        uint256 lastUpdatedRating;
        int256 nextEloUpdate;
    }

    /**
        Update k factor for Elo Rating
    */
    // function updateKFactor(uint256 newKFactor) public onlyOwner {
    //     kFactor = newKFactor;
    //     emit KFactorUpdate(newKFactor);
    // }

    function writeMatchResult(
        GameLibrary.Match memory m,
        GameLibrary.MatchResult result
    ) public override onlyGameContract {
        bytes32 hash = GameLibrary._hashToSignMatch(m);
        require(
            matches[hash].state == MatchState.RUNNING,
            "match isn't running"
        );
        // We save before the update to evict wrong calculation
        int256 ratingA = getPlayerRating(m.playerA);
        int256 ratingB = getPlayerRating(m.playerB);

        // Check for players score
        int256 scoreplayerA = 0;
        int256 scoreplayerB = 0;
        address winner;
        if (result == GameLibrary.MatchResult.PLAYER_A_WIN) {
            scoreplayerA = VICTORY;
            winner = m.playerA;
        } else if (result == GameLibrary.MatchResult.PLAYER_B_WIN) {
            scoreplayerB = VICTORY;
            winner = m.playerB;
        } else {
            scoreplayerA = DRAW;
            scoreplayerB = DRAW;
        }

        // Set the match to finished
        matches[hash].state = MatchState.FINISHED;
        matches[hash].winner = winner;

        // Calculate the expected score for player 1
        // uint256 expectedScore = ((qA * INVERSE_BASIS_POINT) / (qA + qB));
        calculateElo(m.playerA, ratingA - ratingB, scoreplayerA);

        // Calculate the expected score for player 2
        calculateElo(m.playerB, ratingB - ratingA, scoreplayerB);
    }

    /**
        Calculate elo using initial formula
        WIP: It needs some testing how uint handles the decimal part of the formula
    */
    function calculateElo(
        address player,
        int256 diffence,
        int256 scoredPoints
    ) internal {
        int256 eloChange = getScoreChange(diffence, scoredPoints);
        emit EloChange(player, eloChange);
        updatePlayerRating(player, eloChange);
    }

    function getScoreChange(int256 difference, int256 resultA)
        private
        pure
        returns (int256)
    {
        bool reverse = (difference > 0); // note if difference was positive
        uint256 diff = abs(difference); // take absolute to lookup in positive table
        // Score change lookup table
        int256 scoreChange = kFactor / 2;
        if (diff > 636) scoreChange = 20;
        else if (diff > 436) scoreChange = 19;
        else if (diff > 338) scoreChange = 18;
        else if (diff > 269) scoreChange = 17;
        else if (diff > 214) scoreChange = 16;
        else if (diff > 168) scoreChange = 15;
        else if (diff > 126) scoreChange = 14;
        else if (diff > 88) scoreChange = 13;
        else if (diff > 52) scoreChange = 12;
        else if (diff > 17) scoreChange = 11;
        // Depending on result (win/draw/lose), calculate score changes
        if (resultA == int256(VICTORY)) {
            return reverse ? kFactor - scoreChange : scoreChange;
        } else if (resultA == int256(DRAW)) {
            return
                reverse
                    ? kFactor / 2 - scoreChange
                    : scoreChange - kFactor / 2;
        } else {
            return reverse ? scoreChange - kFactor : -scoreChange;
        }
    }

    function abs(int256 value) private pure returns (uint256) {
        if (value >= 0) return uint256(value);
        else return uint256(-1 * value);
    }

    function createMatch(
        GameLibrary.Match memory m,
        GameLibrary.Sig memory pAsig,
        GameLibrary.Sig memory pBsig
    ) public override returns (bytes32 hash) {
        hash = GameLibrary._requireValidMatch(m, pAsig, pBsig);
        require(
            matches[hash].state == MatchState.NOT_STARTED,
            "the game has already started"
        );
        matches[hash].state = MatchState.RUNNING;

        // Emit events
        emit MatchCreate(m.playerA, m.playerB, m.nonce);
    }

    function updatePlayerRating(address p, int256 newEloRating) internal {
        PlayerRating storage rating = playerElo[p];
        int256 eloUpdate = newEloRating;
        if (evaluationPeriod > 0) {
            if (rating.lastUpdatedRating + evaluationPeriod > block.timestamp) {
                rating.nextEloUpdate += eloUpdate;
                return;
            } else {
                eloUpdate += rating.nextEloUpdate;
                rating.nextEloUpdate = 0;
            }
        }

        rating.elo = rating.elo + eloUpdate;
        rating.lastUpdatedRating = block.timestamp;
        emit EloUpdate(p, getPlayerRating(p));
    }

    function getPlayerRating(address p) public view returns (int256 elo) {
        elo = playerElo[p].elo + 1500;
    }

    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            // REMOVED: Binary fraction logic, explained below...

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }
}
