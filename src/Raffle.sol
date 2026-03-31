// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleNotOpened();

    /* Type declarations */
    enum State {
        Open,
        Calculating
    }

    /* State variables */
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subId;
    uint16 private constant CONFIRMATIONS = 3;
    uint32 private constant GAS_LIMIT = 500000;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_interval;
    address payable[] private s_players;
    State private s_state;

    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    /* Events */
    event NewPlayer(address indexed sender);
    event WinnerRequested(address indexed sender);
    event NewWinner(address indexed winner);

    /* Constructor */
    constructor(address vrfCoordinator, uint256 entranceFee, bytes32 keyHash, uint256 subId, uint256 interval)
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        i_entranceFee = entranceFee;
        i_keyHash = keyHash;
        i_subId = subId;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    /* Functions */
    function enterRaffle() external payable {
        // Checks
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }

        if (s_state != State.Open) {
            revert Raffle__RaffleNotOpened();
        }

        // Effects
        s_players.push(payable(msg.sender));

        // Interactions
        emit NewPlayer(msg.sender);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {}

    function performUpkeep(
        bytes calldata /* performData */
    )
        external
        override
    {}

    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    )
        internal
        override
    {}

    /* Getter functions */
    function getPlayers() external view returns (address payable[] memory) {
        return s_players;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
