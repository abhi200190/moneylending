// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract P2PLending {
    struct Loan {
        address payable borrower;
        address payable lender;
        uint256 amount;
        uint256 interestRate; // Interest rate in basis points (e.g., 1000 = 10%)
        uint256 dueDate;
        bool repaid;
    }

    mapping(uint256 => Loan) public loans;
    uint256 public loanCount = 0;

    event LoanRequested(uint256 loanId, address borrower, uint256 amount, uint256 interestRate, uint256 dueDate);
    event LoanFunded(uint256 loanId, address lender);
    event LoanRepaid(uint256 loanId);

    function requestLoan(uint256 amount, uint256 interestRate, uint256 dueDate) external {
        require(amount > 0, "Amount must be greater than zero");
        require(interestRate > 0, "Interest rate must be greater than zero");
        require(dueDate > block.timestamp, "Due date must be in the future");

        loans[loanCount] = Loan({
            borrower: payable(msg.sender),
            lender: payable(address(0)),
            amount: amount,
            interestRate: interestRate,
            dueDate: dueDate,
            repaid: false
        });

        emit LoanRequested(loanCount, msg.sender, amount, interestRate, dueDate);
        loanCount++;
    }

    function fundLoan(uint256 loanId) external payable {
        Loan storage loan = loans[loanId];
        require(loan.lender == address(0), "Loan is already funded");
        require(msg.value == loan.amount, "Incorrect loan amount");

        loan.lender = payable(msg.sender);
        emit LoanFunded(loanId, msg.sender);
    }

    function repayLoan(uint256 loanId) external payable {
        Loan storage loan = loans[loanId];
        require(msg.sender == loan.borrower, "Only the borrower can repay the loan");
        require(!loan.repaid, "Loan is already repaid");

        uint256 totalRepayment = loan.amount + calculateInterest(loan.amount, loan.interestRate, block.timestamp - loan.dueDate);
        require(msg.value == totalRepayment, "Incorrect repayment amount");

        loan.lender.transfer(msg.value);
        loan.repaid = true;
        emit LoanRepaid(loanId);
    }

      function calculateInterest(uint256 principal, uint256 interestRate, uint256 daysLate) internal pure returns (uint256) {
        return (principal * interestRate * daysLate) / (365 * 10000);
    }
}
