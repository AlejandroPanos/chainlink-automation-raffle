// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract TestRaffle is Test {
    /* Instantiate contracts */
    HelperConfig helperConfig;
    Raffle raffle;

    /* State variables */
    address USER = makeAddr("USER");
    uint256 private constant DEAL = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    bytes32 keyHash;
    uint256 subId;
    uint32 callbackGasLimit;
    address vrfCoordinator;

    /* Events */
    event NewPlayer(address indexed sender);
    event NewUpkeep(uint256 indexed request);
    event NewWinner(address indexed winner);

    /* Set up function */
    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (raffle, helperConfig) = deploy.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        keyHash = config.keyHash;
        subId = config.subId;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinator = config.vrfCoordinator;
        vm.deal(USER, DEAL);
    }

    /* General testing functions */

    /* Enter raffle testing functions */

    /* Check & perform upkeep testing functions */

    /* Fulfill random words testing functions */
}
