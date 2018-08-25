pragma solidity 0.4.24;

import "./node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Casino is Ownable {
    event GameStarted(bytes32 indexed gameId, address indexed dealer, uint wager, uint multiples, uint indexed guessEnd, uint revealEnd);
    event NumberGuessed(bytes32 indexed gameId, address indexed player, uint number);
    event GameEnded(bytes32 indexed gameId, address indexed winner, uint value);

    using SafeMath for uint;

    enum State { Ready, WaitingForGuess, WaitingForReveal}
    
    struct Game {
        State state;
        bool dealerWins;
        address dealer;
        address player;
        bytes32 encryptedNumber;
        uint guessedNumber;
        uint wager;
        uint multiples;
        uint guessEnd;
        uint revealEnd;
    }

    mapping(bytes32 => Game) games;
    mapping(address => uint) pendingReturns;

    uint internal minGuessTime = 2 minutes;
    uint internal maxGuessTime = 3 days;
    uint internal minRevealTime = 3 minutes;
    uint internal maxRevealTime = 3 days;
    address internal benificiary =  0xA10ac76eB84ef65EdabA1D869889515224C9f1BF;

    /**
    @dev The dealer creates a game
    @param _gameId game id
    @param _encryptedNumber encryped number by number and secret
    @param _wager unit ether to bet, total wager = _wager * _multiples
    @param _multiples multiples of wager, total wager = _wager * _multiples
    @param _guessTime duration of valid guess
    @param _revealTime duration to reveal. Dealer must reveal his number before reveal time end, or dealer loses.
    */
    function create(bytes32 _gameId, bytes32 _encryptedNumber, uint _wager, uint _multiples, uint _guessTime, uint _revealTime)
        public payable {
        require(_wager >= 10 finney, "Wager is 10 finney at least");
        require(msg.value == _wager.mul(_multiples), "You must send _multiples of _wager");
        require(_guessTime >= minGuessTime && _guessTime <= maxGuessTime, "Guess time is invalid");
        require(_revealTime >= minRevealTime && _revealTime <= maxRevealTime, "Reveal time is invalid");

        Game storage game = games[_gameId];
        require(game.state == State.Ready, "Game is not over");

        uint guessEnd = now + _guessTime;
        uint revealEnd = guessEnd + _revealTime;
        games[_gameId] = Game(State.WaitingForGuess, false, msg.sender, 0, _encryptedNumber, 0, _wager, _multiples, guessEnd, revealEnd);

        emit GameStarted(_gameId, msg.sender, _wager, _multiples, guessEnd, revealEnd);
    }

    /**
    @dev The player guesses a number
    @param _number the number player guesses which should be >= 0 and <= multiples
    */
    function guess(bytes32 _gameId, uint _number) public payable {
        Game storage game = games[_gameId];
        require(_number <= game.multiples, "Number should be less than or equal to multiples");
        require(msg.value == game.wager, "You must send wager");
        require(game.state == State.WaitingForGuess, "");
        require(now < game.guessEnd, "Guess time out");

        game.state = State.WaitingForReveal;
        game.player = msg.sender;
        game.guessedNumber = _number;

        emit NumberGuessed(_gameId, msg.sender, _number);
    }

    /**
    @dev The dealer must reveal his number with secret to win 
    */
    function reveal(bytes32 _gameId, uint _number, bytes32 _secret) public {
        Game storage game = games[_gameId];
        require(msg.sender == game.dealer, "You must be the dealer");
        require(_number <= game.multiples, "Number should be less than or equal to multiples");
        require(game.state == State.WaitingForReveal, "Nobody has guessed");
        require(!game.dealerWins, "You have revealed and winned");
        require(now < game.revealEnd, "Reveal is end");

        bool dealerWins = game.encryptedNumber != keccak256(abi.encodePacked(_number, _secret));
        if (dealerWins) {
            uint amount = game.wager.mul(game.multiples.add(1));
            uint cut = _cut(game.wager);
            uint remaining = amount.sub(cut);
            pendingReturns[benificiary] = pendingReturns[benificiary].add(cut);
            pendingReturns[game.dealer] = pendingReturns[game.dealer].add(remaining);

            game.dealerWins = true;
            game.state = State.Ready;

            emit GameEnded(_gameId, game.dealer, remaining);
        }
    }

    /**
    @dev The dealer may cancel the game before a player guess.
    */
    function cancel(bytes32 _gameId) public {
        Game storage game = games[_gameId];
        require(msg.sender == game.dealer, "You must be the dealer to cancel the game");
        require(game.state == State.WaitingForGuess, "Dealer can't cancel game if there is player has guessed");
        
        uint amount = game.wager.mul(game.multiples);
        pendingReturns[game.dealer] = pendingReturns[game.dealer].add(amount);
        game.state = State.Ready;

        emit GameEnded(_gameId, game.dealer, 0);
    }

    /**
    @dev Anyone can force to end the game after reveal end date, the result is player wins.
    */
    function forceToEnd(bytes32 _gameId) external {
        Game storage game = games[_gameId];
        require(game.state == State.WaitingForReveal, "There is not player guess yet");
        require(now > game.revealEnd, "Reveal is not end");

        uint amount = game.wager.mul(game.multiples.add(1));
        uint cut = _cut(game.wager.mul(game.multiples));
        uint remaining = amount.sub(cut);
        pendingReturns[benificiary] = pendingReturns[benificiary].add(cut);
        pendingReturns[game.player] = pendingReturns[game.player].add(remaining);
        game.state = State.Ready;

        emit GameEnded(_gameId, game.player, remaining);
    }

    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }

    /**
    @dev cut to beniciary on every win.
    */
    function _cut(uint _amount) private pure returns (uint) {
        return _amount.div(10);
    }

    /*----------  OWNER ONLY FUNCTIONS  ----------*/
    function setGuessTimeRange(uint _minGuessTime, uint _maxGuessTime) public onlyOwner {
        minGuessTime = _minGuessTime;
        maxGuessTime = _maxGuessTime;
    }

    function setRevealTimeRange(uint _minRevealTime, uint _maxRevealTime) public onlyOwner {
        minRevealTime = _minRevealTime;
        maxRevealTime = _maxRevealTime;
    }

    function setBenificiary(address _benificiary) public onlyOwner {
        benificiary = _benificiary;
    }
}