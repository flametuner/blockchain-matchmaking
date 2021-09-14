// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IPeriodic {
    function updateEvaluationPeriod(uint256 newEvaluationPeriod) external;

    function nextEvaluationPeriod() external;
}
