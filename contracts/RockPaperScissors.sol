// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RockPaperScissors {
    address public owner;

    struct Game {
        address player1;
        address player2;
        uint256 betAmount;
        uint8 player1Choice;
        uint8 player2Choice;
        uint8 result;
        bool completed;
    }

    Game[] public games;

    constructor() {
        owner = msg.sender;
    }

    enum Choice {
        Rock,
        Paper,
        Scissors
    }

    event ChallengeCreated(
        uint256 gameId,
        address indexed player1,
        address indexed player2,
        uint256 betAmount
    );
    event GameCompleted(
        uint256 gameId,
        address indexed winner,
        address indexed loser,
        uint256 reward
    );

    function createChallenge(
        address opponent,
        uint256 bet,
        uint8 choice
    ) external payable {
        require(choice >= 0 && choice <= 2, "Invalid choice");
        require(opponent != msg.sender, "You cannot challenge yourself");
        require(msg.value == bet, "Sent value must be greater than 0");

        Game memory newGame = Game({
            player1: msg.sender,
            player2: opponent,
            betAmount: bet,
            player1Choice: choice,
            player2Choice: 0, // Initialize to 0, indicating the opponent has not chosen yet.
            result: 0, // Initialize to 0, indicating the game is not completed.
            completed: false
        });

        uint256 gameId = games.length;
        games.push(newGame);

        emit ChallengeCreated(gameId, msg.sender, opponent, bet);
    }

    function acceptChallenge(uint256 gameId, uint256 bet, uint8 choice) external payable {
        require(choice >= 0 && choice <= 2, "Invalid choice");
        require(
            games[gameId].player2 == msg.sender,
            "Only the challenged player can accept the challenge"
        );
        require(msg.value == bet, "Sent value must be greater than 0");

        games[gameId].player2Choice = choice;

        // Determine the winner and update the game result.
        uint8 player1Choice = games[gameId].player1Choice;
        uint8 player2Choice = games[gameId].player2Choice;
        if (player1Choice == player2Choice) {
            games[gameId].result = 0; // Draw
        } else if (
            (player1Choice == uint8(Choice.Rock) &&
                player2Choice == uint8(Choice.Scissors)) ||
            (player1Choice == uint8(Choice.Paper) &&
                player2Choice == uint8(Choice.Rock)) ||
            (player1Choice == uint8(Choice.Scissors) &&
                player2Choice == uint8(Choice.Paper))
        ) {
            games[gameId].result = 1; // Player 1 wins
            payable(games[gameId].player1).transfer(
                2 * games[gameId].betAmount
            ); // Send the reward to Player 1
        } else {
            games[gameId].result = 2; // Player 2 wins
            payable(games[gameId].player2).transfer(
                2 * games[gameId].betAmount
            ); // Send the reward to Player 2
        }

        games[gameId].completed = true;
        emit GameCompleted(
            gameId,
            games[gameId].player1,
            games[gameId].player2,
            2 * games[gameId].betAmount
        );
    }
}
