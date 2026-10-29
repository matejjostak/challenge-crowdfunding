// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./FundingRecipient.sol";

contract CrowdFund {
    /////////////////
    /// Errors //////
    /////////////////

    // Errors go here...

    error NotOpenToWithdraw();
    error WithdrawTransferFailed(address to, uint256 amount);

    error TooEarly(uint256 deadline, uint256 currentTimestamp);

    error AlreadyCompleted();


    //////////////////////
    /// State Variables //
    //////////////////////

    FundingRecipient public fundingRecipient;

    mapping(address => uint256) public balances;

    bool public openToWithdraw;

    uint256 public deadline = block.timestamp + 2 hours;

    uint256 public constant threshold = 1 ether;


    ////////////////
    /// Events /////
    ////////////////

    // Events go here...

    event Contribution(address, uint256);

    ///////////////////
    /// Modifiers /////
    ///////////////////

    modifier notCompleted() {

        if (fundingRecipient.completed()) revert AlreadyCompleted();
        _;
    }

    ///////////////////
    /// Constructor ///
    ///////////////////

    constructor(address fundingRecipientAddress) {
        fundingRecipient = FundingRecipient(fundingRecipientAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////

    function contribute() public payable notCompleted {
        address sender = msg.sender;
        uint256 sentValue = msg.value;
        balances[sender] += sentValue;

        emit Contribution(sender, sentValue);

    }

    function withdraw() public notCompleted{
        if (!openToWithdraw) {
            revert NotOpenToWithdraw();
        }

        uint256 currentBalance = balances[msg.sender];


        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: currentBalance}("");
        if (!success) {
            revert WithdrawTransferFailed(msg.sender, currentBalance);
        }
    }

    function execute() public notCompleted{
        if(deadline >= block.timestamp){
            revert TooEarly(deadline, block.timestamp);
        } else if( threshold <= address(this).balance){
            fundingRecipient.complete{value: address(this).balance}();
        } else {
            openToWithdraw = true;
        }


    }

    receive() external payable {
        contribute();
    }

    ////////////////////////
    /// View Functions /////
    ////////////////////////

    function timeLeft() public view returns (uint256) {

        if(block.timestamp < deadline) {
            return deadline - block.timestamp;
        }

        return 0;
    }
}
