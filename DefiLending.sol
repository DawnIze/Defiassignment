// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./YourCollectible.sol";

error InsufficientBalance();
    error InsufficientLiquidity();
    error NoLoanToRepay();
    error InsufficientRepayment();
    error NoCollateral();


contract DefiLending {
    YourCollectible public nftContract;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public loans;
    mapping(address => uint256) public collateralNFT;
    uint256 public totalDeposits;
    uint256 public totalLoans;
    uint256 public interestRate; // Annual interest rate in basis points (1%=100 basis points)
    uint256 public rewardRate; // Reward rate for withdrawals

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 reward);
    event Loan(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    event CollateralDeposited(address indexed user, uint256 tokenId);
    event CollateralWithdrawn(address indexed user, uint256 tokenId);


    constructor(YourCollectible _nftContract, uint256 _interestRate, uint256 _rewardRate) {
        nftContract = _nftContract;
        interestRate = _interestRate;
        rewardRate = _rewardRate;
    }

    modifier hasDeposit() {
        require(deposits[msg.sender] > 0, "No deposit found");
        _;
    }

    modifier hasLoan() {
        require(loans[msg.sender] > 0, "No loan found");
        _;
    }

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not the owner");
        _;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external hasDeposit {
        if (deposits[msg.sender] < _amount) {
            revert InsufficientBalance();
        }
        uint256 reward = calculateReward(_amount);
        deposits[msg.sender] -= _amount;
        totalDeposits -= _amount;
        payable(msg.sender).transfer(_amount + reward);
        emit Withdraw(msg.sender, _amount, reward);
    }

    function borrow(uint256 _amount, uint256 _tokenId) external {
        if (totalDeposits < totalLoans + _amount) {
            revert InsufficientLiquidity();
        }
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not the owner of NFT");
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        collateralNFT[msg.sender] = _tokenId;

        loans[msg.sender] += _amount;
        totalLoans += _amount;
        payable(msg.sender).transfer(_amount);
        emit Loan(msg.sender, _amount);
        emit CollateralDeposited(msg.sender, _tokenId);
    }

    function repay() external payable hasLoan {
        uint256 interest = (loans[msg.sender] * interestRate) / 10000;
        uint256 totalRepayment = loans[msg.sender] + interest;
        if (msg.value < totalRepayment) {
            revert InsufficientRepayment();
        }
        loans[msg.sender] = 0;
        totalLoans -= msg.value - interest;
        uint256 tokenId = collateralNFT[msg.sender];
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        delete collateralNFT[msg.sender];
        emit Repay(msg.sender, msg.value);
        emit CollateralWithdrawn(msg.sender, tokenId);
    }

    function calculateInterest(uint256 _amount) public view returns (uint256) {
        return (_amount * interestRate) / 10000;
    }

    function calculateReward(uint256 _amount) public view returns (uint256) {
        return (_amount * rewardRate) / 10000;
    }
}
