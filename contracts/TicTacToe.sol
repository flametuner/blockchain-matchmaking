// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RatingSystem.sol";

pragma solidity ^0.8.7;

// TicTacToe is a solidity implementation of the tic tac toe game.
// You can find the rules at https://en.wikipedia.org/wiki/Tic-tac-toe
contract TicTacToe is Ownable {
    // Players enumerates all possible players
    enum Players {
        None,
        PlayerA,
        PlayerB
    }
    // Winners enumerates all possible winners
    enum Winners {
        None,
        PlayerA,
        PlayerB,
        Draw
    }

    // Game stores the state of a round of tic tac toe.
    // As long as `winner` is `None`, the game is not over.
    // `playerTurn` defines who may go next.
    // Player one must make the first move.
    // The `board` has the size 3x3 and in each cell, a player
    // can be listed. Initializes as `None` player, as that is the
    // first element in the enumeration.
    // That means that players are free to fill in any cell at the
    // start of the game.
    struct Game {
        address playerA;
        address playerB;
        uint256 nonce;
        Winners winner;
        Players playerTurn;
        Players[3][3] board;
    }

    // games stores all the games.
    // Games that are already over as well as games that are still running.
    // It is possible to iterate over all games, as the keys of the mapping
    // are known to be the integers from `1` to `nrOfGames`.
    mapping(bytes32 => Game) public games;
    // nrOfGames stores the total number of games in this contract.

    RatingSystem public _system;

    // GameCreated signals that `creator` created a new game with this `gameId`.
    event GameCreated(bytes32 gameId, address creator);
    // PlayerJoinedGame signals that `player` joined the game with the id `gameId`.
    // That player has the player number `playerNumber` in that game.
    event PlayerJoinedGame(bytes32 gameId, address player, uint8 playerNumber);
    // PlayerMadeMove signals that `player` filled in the board of the game with
    // the id `gameId`. She did so at the coordinates `xCoordinate`, `yCoordinate`.
    event PlayerMadeMove(
        bytes32 gameId,
        address player,
        uint256 xCoordinate,
        uint256 yCoordinate
    );
    // GameOver signals that the game with the id `gameId` is over.
    // The winner is indicated by `winner`. No more moves are allowed in this game.
    event GameOver(bytes32 gameId, Winners winner);

    function updateRatingSystem(RatingSystem system) public onlyOwner {
        _system = system;
    }

    // newGame creates a new game and returns the new game's `gameId`.
    // The `gameId` is required in subsequent calls to identify the game.
    function newGame(
        GameLibrary.Match memory m,
        GameLibrary.Sig memory pAsig,
        GameLibrary.Sig memory pBsig
    ) public returns (bytes32 gameId) {
        require(address(_system) != address(0), "rating system not defined");
        bytes32 _gameId = _system.createMatch(m, pAsig, pBsig);
        Game storage game = games[_gameId];
        game.playerTurn = Players.PlayerA;
        game.playerA = m.playerA;
        game.playerB = m.playerB;
        game.nonce = m.nonce;


        emit GameCreated(_gameId, msg.sender);
        emit PlayerJoinedGame(_gameId, game.playerA, uint8(Players.PlayerA));
        emit PlayerJoinedGame(_gameId, game.playerB, uint8(Players.PlayerB));
        return _gameId;
    }

    // makeMove inserts a player on the game board.
    // The player is identified as the sender of the message.
    function makeMove(
        bytes32 _gameId,
        uint256 _xCoordinate,
        uint256 _yCoordinate
    ) public returns (bool success, string memory reason) {
        Game storage game = games[_gameId];

        if (game.playerA == address(0) || game.playerB == address(0)) {
            return (false, "No such game exists.");
        }

        // Any winner other than `None` means that no more moves are allowed.
        if (game.winner != Winners.None) {
            return (false, "The game has already ended.");
        }

        // Only the player whose turn it is may make a move.
        if (msg.sender != getCurrentPlayer(game)) {
            return (false, "It is not your turn.");
        }

        // Players can only make moves in cells on the board that have not been played before.
        if (game.board[_xCoordinate][_yCoordinate] != Players.None) {
            return (false, "There is already a mark at the given coordinates.");
        }

        // Now the move is recorded and the according event emitted.
        game.board[_xCoordinate][_yCoordinate] = game.playerTurn;
        emit PlayerMadeMove(_gameId, msg.sender, _xCoordinate, _yCoordinate);

        // Check if there is a winner now that we have a new move.
        Winners winner = calculateWinner(game.board);
        if (winner != Winners.None) {
            // If there is a winner (can be a `Draw`) it must be recorded in the game and
            // the corresponding event must be emitted.
            game.winner = winner;

            emit GameOver(_gameId, winner);

            GameLibrary.MatchResult result = GameLibrary.MatchResult.DRAW;
            if (winner == Winners.PlayerA) {
                result = GameLibrary.MatchResult.PLAYER_A_WIN;
            } else if (winner == Winners.PlayerB) {
                result = GameLibrary.MatchResult.PLAYER_B_WIN;
            }

            _system.writeMatchResult(GameLibrary.Match(game.playerA, game.playerB, game.nonce), result);
            return (true, "The game is over.");
        }

        // A move was made and there is no winner yet.
        // The next player should make her move.
        nextPlayer(game);

        return (true, "");
    }

    // getCurrentPlayer returns the address of the player that should make the next move.
    // Returns the `0x0` address if it is no player's turn.
    function getCurrentPlayer(Game storage _game)
        private
        view
        returns (address player)
    {
        if (_game.playerTurn == Players.PlayerA) {
            return _game.playerA;
        }

        if (_game.playerTurn == Players.PlayerB) {
            return _game.playerB;
        }

        return address(0);
    }

    // calculateWinner returns the winner on the given board.
    // The returned winner can be `None` in which case there is no winner and no draw.
    function calculateWinner(Players[3][3] memory _board)
        private
        pure
        returns (Winners winner)
    {
        // First we check if there is a victory in a row.
        // If so, convert `Players` to `Winners`
        // Subsequently we do the same for columns and diagonals.
        Players player = winnerInRow(_board);
        if (player == Players.PlayerA) {
            return Winners.PlayerA;
        }
        if (player == Players.PlayerB) {
            return Winners.PlayerB;
        }

        player = winnerInColumn(_board);
        if (player == Players.PlayerA) {
            return Winners.PlayerA;
        }
        if (player == Players.PlayerB) {
            return Winners.PlayerB;
        }

        player = winnerInDiagonal(_board);
        if (player == Players.PlayerA) {
            return Winners.PlayerA;
        }
        if (player == Players.PlayerB) {
            return Winners.PlayerB;
        }

        // If there is no winner and no more space on the board,
        // then it is a draw.
        if (isBoardFull(_board)) {
            return Winners.Draw;
        }

        return Winners.None;
    }

    // winnerInRow returns the player that wins in any row.
    // To win in a row, all cells in the row must belong to the same player
    // and that player must not be the `None` player.
    function winnerInRow(Players[3][3] memory _board)
        private
        pure
        returns (Players winner)
    {
        for (uint8 x = 0; x < 3; x++) {
            if (
                _board[x][0] == _board[x][1] &&
                _board[x][1] == _board[x][2] &&
                _board[x][0] != Players.None
            ) {
                return _board[x][0];
            }
        }

        return Players.None;
    }

    // winnerInColumn returns the player that wins in any column.
    // To win in a column, all cells in the column must belong to the same player
    // and that player must not be the `None` player.
    function winnerInColumn(Players[3][3] memory _board)
        private
        pure
        returns (Players winner)
    {
        for (uint8 y = 0; y < 3; y++) {
            if (
                _board[0][y] == _board[1][y] &&
                _board[1][y] == _board[2][y] &&
                _board[0][y] != Players.None
            ) {
                return _board[0][y];
            }
        }

        return Players.None;
    }

    // winnerInDiagoral returns the player that wins in any diagonal.
    // To win in a diagonal, all cells in the diaggonal must belong to the same player
    // and that player must not be the `None` player.
    function winnerInDiagonal(Players[3][3] memory _board)
        private
        pure
        returns (Players winner)
    {
        if (
            _board[0][0] == _board[1][1] &&
            _board[1][1] == _board[2][2] &&
            _board[0][0] != Players.None
        ) {
            return _board[0][0];
        }

        if (
            _board[0][2] == _board[1][1] &&
            _board[1][1] == _board[2][0] &&
            _board[0][2] != Players.None
        ) {
            return _board[0][2];
        }

        return Players.None;
    }

    // isBoardFull returns true if all cells of the board belong to a player other
    // than `None`.
    function isBoardFull(Players[3][3] memory _board)
        private
        pure
        returns (bool isFull)
    {
        for (uint8 x = 0; x < 3; x++) {
            for (uint8 y = 0; y < 3; y++) {
                if (_board[x][y] == Players.None) {
                    return false;
                }
            }
        }

        return true;
    }

    // nextPlayer changes whose turn it is for the given `_game`.
    function nextPlayer(Game storage _game) private {
        if (_game.playerTurn == Players.PlayerA) {
            _game.playerTurn = Players.PlayerB;
        } else {
            _game.playerTurn = Players.PlayerA;
        }
    }
}
