// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title A sample Raffle contract
 * @author Manoj kumar patil
 * @notice This contract is for creating a sample Raffle
 * @dev Implements Chainlink VRFv2.5
 */

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendmoreToEnterRaffle();

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery in second.
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimestamp;
    address payable[] private s_players; // The list of players entering into the raffle
    // who ever wins it should be paid to them. then make it as a 'payable'.

    /**  EVENTS */
    event RaffleEntered(address indexed player);

    /**We need to use the constructor of inherited codebase(VRFConsumerBaseV2Plus),
     * Then it needs a vrfCoordinator address, will pass to our constructor
     * from our constructor to their constructor(VRFConsumerBaseV2Plus constructor)
     */

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee , "Not enough eth sent!");  // This is not gas efficient becoz, using a string to print consumes more gas
        // require(msg.value >= i_entranceFee, SendmoreToEnterRaffle());  // It works on specific compiler version (low level) newer version(v0.8.26)
        if (msg.value < i_entranceFee) {
            revert Raffle__SendmoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender)); // here payable keyword becoz, to receive an eth to address.

        emit RaffleEntered(msg.sender); //Anytime you update the storage variable, then emit the event

        // Events helps in two ways
        // 1. Makes migeration easier
        // 2. Makes frontend "indexing" easier
    }

    // 1. get a random number
    // 2. use random number to pick a player
    // 3. Be automatically called
    function pickWinner() external {
        // check to see if enoough time as passed
        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert();
        }
        // Get our random number 2.5
        // 1. Request RNG
        // 2. Get RNG

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {}

    /** Getter function */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
