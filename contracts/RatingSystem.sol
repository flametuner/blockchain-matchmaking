// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRating.sol";
import "../interfaces/IPeriodic.sol";

abstract contract RatingSystem is Ownable, IRating, IPeriodic {
    /* 2 decimal plates for percentage */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    address private _gameContract;
    uint256 public evaluationPeriod;

    uint256 public currentEvaluationPeriod;

    mapping(bytes32 => RunningMatch) matches;

    event PeriodCompleted(uint256 newEvaluationPeriod);

    event MatchCreate(
        address indexed pA,
        address indexed pB,
        uint256 timestamp
    );
    event MatchFinish(
        address indexed pA,
        address indexed pB,
        uint256 timestamp
    );

    struct RunningMatch {
        MatchState state;
        address winner;
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

    function alterGameContract(address newGameAddress) public onlyOwner {
        _gameContract = newGameAddress;
    }

    function updateEvaluationPeriod(uint256 newEvaluationPeriod)
        public
        override
        onlyOwner
    {
        evaluationPeriod = newEvaluationPeriod;
    }

    function nextEvaluationPeriod() public override {
        require(evaluationPeriod > 0, "evaluation period isn't set");
        require(block.timestamp > currentEvaluationPeriod, "it isn't time yet");
        currentEvaluationPeriod = block.timestamp + evaluationPeriod;
        emit PeriodCompleted(currentEvaluationPeriod);
    }

    // function joinQueue() public virtual;

    // function leaveQueue() public virtual;

    // function evaluateMatches() public virtual;

    // function alterRanking() public onlyGameContract {}

    function createMatch(
        GameLibrary.Match memory m,
        GameLibrary.Sig memory pAsig,
        GameLibrary.Sig memory pBsig
    ) public virtual override returns (bytes32 hash);

    function writeMatchResult(
        GameLibrary.Match memory m,
        GameLibrary.MatchResult result
    ) public virtual override onlyGameContract {}

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
    ) internal pure returns (bool) {
        // require(
        //     ecrecover(hash, sigpB.v, sigpB.r, sigpB.s) == m.playerB.addr,
        //     "sig B not correct"
        // );
        // require(
        //     ecrecover(hash, sigpA.v, sigpA.r, sigpA.s) == m.playerA.addr,
        //     "sig A not correct"
        // );
        

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
