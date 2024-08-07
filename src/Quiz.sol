// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz {
    struct Quiz_item {
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }

    mapping(address => uint256)[] public bets;
    uint public vault_balance;

    Quiz_item[] private quizzes;
    uint public prev_quiz_id;
    mapping(address => mapping(uint => bool)) public correctSolutions; // 각 퀴즈에 대한 해결 상태를 추적

    constructor() {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        require(msg.sender != address(1));
        require(q.id == prev_quiz_id + 1, "Invalid quiz ID");
        quizzes.push(q);
        prev_quiz_id = q.id;
        bets.push();
    }

    function getAnswer(uint quizId) public view returns (string memory) {
        return quizzes[quizId - 1].answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory q = quizzes[quizId - 1];
        q.answer = "";
        return q;
    }

    function getQuizNum() public view returns (uint) {
        return prev_quiz_id;
    }

    function betToPlay(uint quizId) public payable {
        require(quizId > 0 && quizId <= quizzes.length, "Invalid quiz ID");

        Quiz_item memory q = quizzes[quizId - 1];
        require(
            msg.value >= q.min_bet && msg.value <= q.max_bet,
            "Bet amount out of range"
        );

        bets[quizId - 1][msg.sender] += msg.value;
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        bool result = keccak256(abi.encodePacked(ans)) ==
            keccak256(abi.encodePacked(quizzes[quizId - 1].answer));
        if (result) {
            correctSolutions[msg.sender][quizId] = true;
        } else {
            vault_balance += bets[quizId - 1][msg.sender];
            bets[quizId - 1][msg.sender] = 0;
        }
        return result;
    }

    function claim() public {
        uint256 totalReward = 0;

        for (uint256 i = 0; i < quizzes.length; i++) {
            if (correctSolutions[msg.sender][i + 1]) {
                uint256 amount = bets[i][msg.sender];
                if (amount > 0) {
                    totalReward += amount;
                    bets[i][msg.sender] = 0;
                    correctSolutions[msg.sender][i + 1] = false; // 재청구 방지
                }
            }
        }

        require(totalReward > 0, "No rewards to claim");

        uint256 payout = totalReward * 2;
        require(vault_balance >= payout, "Not enough balance in vault");

        vault_balance -= payout;
        payable(msg.sender).transfer(payout);
    }

    receive() external payable {
        vault_balance += msg.value;
    }
}
