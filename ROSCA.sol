// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ROSCA {
    struct Member {
        address payable memberAddress;
        uint256 contribution;
        uint256 balance;
        bool hasWithdrawn;
    }

    address public admin;
    uint256 public contributionAmount;
    uint256 public cycleDuration;
    uint256 public currentCycle;
    uint256 public memberCount;
    uint256 public totalContribution;
    uint256 public startTime;
    uint256 public membersWithdrawn;

    mapping(uint256 => Member[]) public cycles;
    mapping(address => bool) public isMember;

    event MemberJoined(address indexed member, uint256 cycle);
    event ContributionMade(address indexed member, uint256 amount, uint256 cycle);
    event Withdrawal(address indexed member, uint256 amount, uint256 cycle);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function");
        _;
    }

    constructor(uint256 _contributionAmount, uint256 _cycleDuration) {
        admin = msg.sender;
        contributionAmount = _contributionAmount;
        cycleDuration = _cycleDuration;
        currentCycle = 1;
        startTime = block.timestamp;
    }

    function joinROSCA() external payable {
        require(msg.value == contributionAmount, "Incorrect contribution amount");
        require(!isMember[msg.sender], "Already a member");

        Member memory newMember = Member({
            memberAddress: payable(msg.sender),
            contribution: msg.value,
            balance: 0,
            hasWithdrawn: false
        });

        cycles[currentCycle].push(newMember);
        isMember[msg.sender] = true;
        memberCount++;
        totalContribution += msg.value;

        emit MemberJoined(msg.sender, currentCycle);
    }

    function contribute() external payable onlyMember {
        require(block.timestamp < startTime + cycleDuration, "Contribution period is over");
        require(msg.value == contributionAmount, "Incorrect contribution amount");

        for (uint256 i = 0; i < cycles[currentCycle].length; i++) {
            if (cycles[currentCycle][i].memberAddress == msg.sender) {
                cycles[currentCycle][i].contribution += msg.value;
                totalContribution += msg.value;
                emit ContributionMade(msg.sender, msg.value, currentCycle);
                return;
            }
        }
    }

    function withdraw() external onlyMember {
        require(block.timestamp >= startTime + cycleDuration, "Cannot withdraw before cycle ends");

        for (uint256 i = 0; i < cycles[currentCycle].length; i++) {
            if (cycles[currentCycle][i].memberAddress == msg.sender && !cycles[currentCycle][i].hasWithdrawn) {
                uint256 amount = totalContribution / memberCount;
                cycles[currentCycle][i].balance += amount;
                cycles[currentCycle][i].hasWithdrawn = true;
                membersWithdrawn++;
                totalContribution -= amount;

                payable(msg.sender).transfer(amount);

                emit Withdrawal(msg.sender, amount, currentCycle);
                return;
            }
        }

        if (membersWithdrawn == memberCount) {
            startNewCycle();
        }
    }

    function startNewCycle() internal {
        currentCycle++;
        startTime = block.timestamp;
        totalContribution = 0;
        membersWithdrawn = 0;
    }
}
