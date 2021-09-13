// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MatchMaking is Ownable {
    /* 2 decimal plates for percentage */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    address private _gameContract;
    uint256 public evaluationPeriod;

    uint256 public currentEvaluationPeriod;

    mapping(bytes32 => RunningMatch) matches;

    event PeriodCompleted(uint256 newEvaluationPeriod);

    event MatchCreate(
        address indexed p1,
        address indexed p2,
        uint256 timestamp
    );
    event MatchFinish(
        address indexed p1,
        address indexed p2,
        uint256 timestamp
    );

    /**
        Match against 2 players in a timestamp
        WIP Need to check if nonce is needed
    */

    struct Match {
        address player1;
        address player2;
        uint256 timestamp;
    }

    struct RunningMatch {
        MatchState state;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum MatchResult {
        DRAW,
        PLAYER1_WIN,
        PLAYER2_WIN
    }

    enum MatchState {
        NOT_STARTED,
        RUNNING,
        FINISHED
    }

    constructor(address gameContract) {
        _gameContract = gameContract;
    }

    modifier onlyGameContract() {
        require(_msgSender() == _gameContract, "Only GameContract Allowed");
        _;
    }

    function updateEvaluationPeriod(uint256 newEvaluationPeriod)
        public
        onlyOwner
    {
        evaluationPeriod = newEvaluationPeriod;
    }

    function nextEvaluationPeriod() public {
        require(evaluationPeriod > 0, "evaluation period isn't set");
        require(block.timestamp > currentEvaluationPeriod, "it isn't time yet");
        currentEvaluationPeriod = block.timestamp + evaluationPeriod;
        emit PeriodCompleted(currentEvaluationPeriod);
    }

    // function joinQueue() public virtual;

    // function leaveQueue() public virtual;

    // function evaluateMatches() public virtual;

    function confirmMatch(
        Match memory m,
        Sig memory p1sig,
        Sig memory p2sig
    ) public virtual;

    function writeMatchResult(Match memory m, MatchResult result)
        public
        onlyGameContract
    {}

    function alterRanking() public onlyGameContract {}

    function alterGameContract(address newGameAddress) public onlyOwner {
        _gameContract = newGameAddress;
    }

    function requireValidMatch(
        Match memory m,
        Sig memory sigp1,
        Sig memory sigp2
    ) internal pure returns (bytes32 hash) {
        require(
            validateMatch(m, hash = hashToSignMatch(m), sigp1, sigp2),
            "invalid match"
        );
    }

    function validateMatch(
        Match memory m,
        bytes32 hash,
        Sig memory sigp1,
        Sig memory sigp2
    ) internal pure returns (bool) {
        return
            ecrecover(hash, sigp1.v, sigp1.r, sigp1.s) == m.player1 &&
            ecrecover(hash, sigp2.v, sigp2.r, sigp2.s) == m.player2;
    }

    function hashToSignMatch(Match memory m) internal pure returns (bytes32) {
        return hashToSign(hashMatch(m));
    }

    function hashMatch(Match memory m) internal pure returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(m.player1, m.player2, m.timestamp));
    }

    function hashToSign(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}
