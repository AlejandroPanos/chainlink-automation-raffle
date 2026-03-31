# AutoRaffle

A provably fair, fully automated on-chain raffle contract built on Solidity. Players enter by paying an entrance fee and Chainlink Automation monitors the contract on every block, triggering winner selection automatically once the configured interval elapses. Chainlink VRF V2.5 provides cryptographically verifiable randomness for winner selection, making the outcome tamper-proof and publicly auditable. The raffle resets automatically after each round.

---

## What It Does

- Players enter the raffle by paying a fixed entrance fee in ETH
- Chainlink Automation monitors the contract and triggers winner selection automatically once the interval elapses and all conditions are met
- Chainlink VRF V2.5 selects the winner using verifiable randomness
- The winner receives the entire pot in a single transfer
- The raffle resets automatically after each round
- New entries are blocked while winner selection is in progress
- Direct ETH transfers to the contract are rejected

---

## Project Structure

```
.
├── src/
│   └── Raffle.sol                          # Main contract
├── script/
│   ├── DeployRaffle.s.sol                  # Foundry deploy script
│   └── HelperConfig.s.sol                  # Network configuration and mock deployment
└── test/
    ├── unit/
    │   └── TestRaffle.t.sol                # Unit tests
    └── mocks/
        ├── VRFCoordinatorV2_5Mock.sol      # Chainlink VRF coordinator mock
        └── LinkToken.sol                   # Mock LINK token for local testing
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Install dependencies and build

```bash
forge install
forge build
```

### Run tests

```bash
forge test
```

### Run tests with gas report

```bash
forge test --gas-report
```

### Run tests with coverage

```bash
forge coverage
```

### Deploy to a local Anvil chain

In one terminal, start Anvil:

```bash
anvil
```

In another terminal, run the deploy script:

```bash
forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Deploy to Sepolia

Before deploying to Sepolia, create and fund a VRF subscription at [vrf.chain.link](https://vrf.chain.link) and register an Automation upkeep at [automation.chain.link](https://automation.chain.link). Update the `subId` in `HelperConfig.s.sol` with your subscription ID before deploying.

```bash
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

After deploying, add your contract address as a consumer on the Chainlink VRF dashboard and as the target contract on the Automation dashboard.

---

## Contract Overview

### Raffle Lifecycle

```
Open -> Calculating -> Open -> ...
```

- Open: players can enter, Chainlink Automation monitors conditions
- Calculating: winner selection in progress via VRF, new entries blocked

### Automation Conditions

Chainlink Automation calls `checkUpkeep()` on every block. `performUpkeep()` is triggered automatically when all four conditions are simultaneously true:

- Enough time has elapsed since the last round
- The raffle is in Open state
- At least one player has entered
- The contract holds a non-zero ETH balance

### State

| Variable             | Type                | Description                                    |
| -------------------- | ------------------- | ---------------------------------------------- |
| `i_entranceFee`      | `uint256`           | Fixed ETH amount required to enter             |
| `i_interval`         | `uint256`           | Minimum seconds between rounds                 |
| `i_keyHash`          | `bytes32`           | Chainlink gas lane key hash                    |
| `i_subId`            | `uint256`           | Chainlink VRF subscription ID                  |
| `s_players`          | `address payable[]` | Current round participants                     |
| `s_lastTimeStamp`    | `uint256`           | Timestamp of the last round start              |
| `s_recentWinner`     | `address`           | Address of the most recent winner              |
| `s_state`            | `State`             | Current raffle state (Open or Calculating)     |
| `CONFIRMATIONS`      | `uint16`            | Block confirmations before VRF fulfillment (3) |
| `CALLBACK_GAS_LIMIT` | `uint32`            | Gas limit for the VRF callback (500,000)       |
| `NUM_WORDS`          | `uint32`            | Number of random words requested (1)           |

### Functions

| Function                                 | Visibility          | Description                                                                                       |
| ---------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------- |
| `enterRaffle()`                          | `external payable`  | Enters the caller into the current round. Requires minimum ETH and Open state.                    |
| `checkUpkeep(bytes memory)`              | `public view`       | Returns true when all automation conditions are met. Called off-chain by Chainlink nodes.         |
| `performUpkeep(bytes calldata)`          | `external`          | Triggers winner selection. Called on-chain by Chainlink Automation when checkUpkeep returns true. |
| `fulfillRandomWords(uint256, uint256[])` | `internal override` | VRF callback. Selects winner, transfers pot, resets state.                                        |
| `getEntranceFee()`                       | `external view`     | Returns the entrance fee in wei                                                                   |
| `getInterval()`                          | `external view`     | Returns the round interval in seconds                                                             |
| `getSubId()`                             | `external view`     | Returns the VRF subscription ID                                                                   |
| `getKeyHash()`                           | `external view`     | Returns the Chainlink gas lane key hash                                                           |
| `getCallbackGasLimit()`                  | `external pure`     | Returns the VRF callback gas limit                                                                |
| `getNumWords()`                          | `external pure`     | Returns the number of random words requested                                                      |
| `getReqConfirmations()`                  | `external pure`     | Returns the required block confirmations                                                          |
| `getRaffleState()`                       | `external view`     | Returns the current State enum value                                                              |
| `getLastTimestamp()`                     | `external view`     | Returns the timestamp of the last round start                                                     |
| `getRecentWinner()`                      | `external view`     | Returns the most recent winner address                                                            |
| `getPlayer(uint256)`                     | `external view`     | Returns the player address at a given index                                                       |
| `getPlayersLength()`                     | `external view`     | Returns the number of current players                                                             |
| `getContractBalance()`                   | `external view`     | Returns the current ETH balance of the contract                                                   |

### Custom Errors

| Error                                 | When It Triggers                                      |
| ------------------------------------- | ----------------------------------------------------- |
| `Raffle__NotEnoughEthSent()`          | ETH sent is below the entrance fee                    |
| `Raffle__RaffleNotOpened()`           | enterRaffle() called when not in Open state           |
| `Raffle__UpkeepNotNeeded()`           | performUpkeep() called when checkUpkeep returns false |
| `Raffle__TransferNotCompleted()`      | ETH transfer to the winner fails                      |
| `Raffle__DirectTransfersNotAllowed()` | ETH sent directly via receive() or fallback()         |

### Events

| Event                                | When It Emits                                          |
| ------------------------------------ | ------------------------------------------------------ |
| `NewPlayer(address indexed sender)`  | A player successfully enters the raffle                |
| `NewUpkeep(uint256 indexed request)` | Winner selection is triggered, includes VRF request ID |
| `NewWinner(address indexed winner)`  | A winner is selected and paid                          |

---

## HelperConfig

Handles network detection and infrastructure configuration automatically.

| Network       | Chain ID | Behaviour                                                                                  |
| ------------- | -------- | ------------------------------------------------------------------------------------------ |
| Sepolia       | 11155111 | Uses real Chainlink VRF coordinator at 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B          |
| Anvil (local) | 31337    | Deploys VRFCoordinatorV2_5Mock and LinkToken, creates and funds subscription automatically |

The deploy script handles subscription creation, funding, and consumer registration automatically on Anvil. On Sepolia these steps are performed manually via the Chainlink dashboards.

---

## Tests

30 tests covering all contract functions and post-settlement state.

### General

| Test                            | What It Checks                   |
| ------------------------------- | -------------------------------- |
| `testRaffleStartsWithOpenState` | Raffle initialises in Open state |

### enterRaffle()

| Test                                  | What It Checks                                      |
| ------------------------------------- | --------------------------------------------------- |
| `testRevertsIfNotEnoughEthSent`       | Reverts when ETH sent is below the entrance fee     |
| `testRevertsIfStateNotOpened`         | Reverts when raffle is in Calculating state         |
| `testPlayerGetsAddedToArray`          | Player address is stored in the players array       |
| `testEmitsNewRaffleWhenRaffleEntered` | NewPlayer event is emitted with the correct address |

### checkUpkeep() and performUpkeep()

| Test                                                  | What It Checks                                      |
| ----------------------------------------------------- | --------------------------------------------------- |
| `testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed` | Returns false when interval has not elapsed         |
| `testCheckUpkeepReturnsFalseIfStateIsCalculating`     | Returns false when raffle is in Calculating state   |
| `testCheckUpkeepReturnsFalseIfNoPlayersAndNoBalance`  | Returns false when no players have entered          |
| `testCheckUpkeepReturnsTrueWhenAllConditionsMet`      | Returns true when all four conditions are satisfied |
| `testPerformUpkeepRevertsIfNoUpkeepIsNeeded`          | Reverts when checkUpkeep returns false              |

### fulfillRandomWords()

| Test                                       | What It Checks                                             |
| ------------------------------------------ | ---------------------------------------------------------- |
| `testFulfillRandomWordsPicksWinner`        | Correct winner is selected from the players array          |
| `testFulfillRandomWordsPicksWinnerAndPays` | Contract balance is zero after the winner is paid          |
| `testRaffleStateGetsBackToOpened`          | State resets to Open after settlement                      |
| `testPlayerArrayResetsToZeroLength`        | Players array is cleared after settlement                  |
| `testLastTimestampResets`                  | Last timestamp is updated after settlement                 |
| `testEmitsWinnerPicked`                    | NewWinner event is emitted with the correct winner address |

### Getter functions

| Test                                       | What It Checks                                        |
| ------------------------------------------ | ----------------------------------------------------- |
| `testGetEntranceFee`                       | Entrance fee matches config value                     |
| `testGetInterval`                          | Interval matches config value                         |
| `testGetKeyHash`                           | Key hash matches config value                         |
| `testGetCallbackGasLimit`                  | Callback gas limit matches config value               |
| `testGetNumWords`                          | Number of words is 1                                  |
| `testGetReqConfirmations`                  | Request confirmations is 3                            |
| `testGetRaffleStateIsOpenOnDeploy`         | Initial state is Open                                 |
| `testGetLastTimestamp`                     | Last timestamp is set at deployment                   |
| `testGetContractBalanceIsZeroOnDeploy`     | Initial balance is zero                               |
| `testGetRecentWinnerIsZeroAddressOnDeploy` | Recent winner is zero address on deploy               |
| `testGetPlayerReturnsCorrectAddress`       | Player address is retrievable by index                |
| `testGetSubId`                             | Subscription ID is greater than zero after deployment |

---

## Dependencies

- [Chainlink VRF V2.5](https://docs.chain.link/vrf) — verifiable random number generation
- [Chainlink Automation](https://docs.chain.link/chainlink-automation) — automated contract execution
- [Solady ERC20](https://github.com/vectorized/solady) — mock LINK token implementation

---

## License

MIT
