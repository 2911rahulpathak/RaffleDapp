// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract Vitto is ReentrancyGuard, VRFConsumerBaseV2, ConfirmedOwner {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    //paying thing
    IERC20 paytoken; //address asssociated to paytoken that we'll deploy
    uint256 public currentLotteryId;
    uint256 public currentTicketId;
    uint256 public ticketPrice = 10 ether;
    uint256 public serviceFee = 3000; // BASIS POINTS 3000 is 30% -> profit fees that we'll get from SC
    uint256 public numberWinner;

    VRFCoordinatorV2Interface COORDINATOR; //this is the coordinator

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 2500000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 6;

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
     */
    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function closeLottery() external onlyOwner {
        /*
        Request Id Stores the ChainLink VRF request Id, this is fetched once we execute the function
        and from there we will obtain a random number that we can use to obtain the winning numbers.
        */
        uint256 requestId;

        /*
        Lets finally call ChainLink VRFv2 and obtain the winning numbers from the randomness generator.
        */
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            exists: true,
            randomWords: new uint256[](0)
        });
        lastRequestId = requestId;
    }

    //getting slice
    function getWinningNumbers()
        external
        view
        onlyOwner
        returns (uint[6] memory)
    {
        uint256[] memory numArray = s_requests[lastRequestId].randomWords;
        uint num1 = numArray[0] % 20;
        uint num2 = numArray[1] % 20;
        uint num3 = numArray[2] % 20;
        uint num4 = numArray[3] % 20;
        uint num5 = numArray[4] % 20;
        uint num6 = numArray[5] % 20;
        uint[6] memory finalNumbers = [num1, num2, num3, num4, num5, num6];
        return finalNumbers;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
