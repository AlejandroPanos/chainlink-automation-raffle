// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleNotOpened();
    error Raffle__UpkeepNotNeeded();
    error Raffle__TransferNotCompleted();

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
    event NewUpkeep(uint256 indexed request);
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
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // Checks
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool stateIsOpen = s_state == State.Open;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;

        // Effects
        upkeepNeeded = timeHasPassed && stateIsOpen && hasPlayers && hasBalance;

        // Interactions
        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    )
        external
        override
    {
        // Checks
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }

        // Effects
        s_state = State.Calculating;

        // Interactions
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subId,
                requestConfirmations: CONFIRMATIONS,
                callbackGasLimit: GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        emit NewUpkeep(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    )
        internal
        override
    {
        // Effects
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        uint256 amount = address(this).balance;
        s_state = State.Open;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit NewWinner(winner);

        // Interactions
        (bool success,) = winner.call{value: amount}("");
        if (!success) {
            revert Raffle__TransferNotCompleted();
        }
    }

    /* Getter functions */
    function getPlayers() external view returns (address payable[] memory) {
        return s_players;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
