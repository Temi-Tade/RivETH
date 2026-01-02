// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Raffle {
    // enter raffle with ETH
    // gen rand number and pick winner
    // send money to winner and reset storage variables

    // assign roles

    error Raffle__NotOwner();
    error Raffle__NotAssigned();
    error Raffle__SendMoreETH();
    error Raffle__RaffleNotOpen();
    error Raffle__CannotPickWinnerYet();
    error Raffle__ETHTransferError();

    event EnterRaffle(address indexed player, uint256 fee);
    event PickWinner(address indexed winner, uint256 amount);

    constructor(uint256 _interval) {
        s_lastTimestamp = block.timestamp;
        i_interval = _interval;
        i_owner = msg.sender;
        roles[msg.sender] = _createRole("MODERATOR");
    }

    uint256 s_lastTimestamp;
    address payable[] s_players;
    address s_recentWinner;
    RaffleState s_raffleState;
    address immutable i_owner;
    uint256 immutable i_interval;
    uint256 immutable i_entryFee = 0.01 ether;
    mapping(address => bytes32) roles;

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Raffle__NotOwner();
        }
        _;
    }

    modifier onlyAssigned(string memory _role) {
        if (roles[msg.sender] != _createRole(_role)) {
            revert Raffle__NotAssigned();
        }
        _;
    }

    function _createRole(string memory _roleName) internal pure returns(bytes32) {
        return keccak256(abi.encode(_roleName));
    }

    function generateRandomNumber() internal view returns(uint256) {
        return block.prevrandao;
    }

    function assignRole(address _account, string memory _role) public onlyOwner {
        roles[_account] = _createRole(_role);
    }

    function enterRaffle() public payable {
        if (msg.value != i_entryFee) {
            revert Raffle__SendMoreETH();
        }
        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit EnterRaffle(msg.sender, msg.value);
    }

    function pickWinner() external onlyAssigned("MODERATOR") {
        // checks: time has passed? raffle is open?
        // RNG
        // pick winner
        // reset storage
        s_raffleState = RaffleState.CALCULATING;

        bool hasTimePassed = (block.timestamp - s_lastTimestamp) > i_interval;
        bool hasFunds = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        bool isNotOpen = s_raffleState == RaffleState.CALCULATING;

        if (hasTimePassed && hasFunds && hasPlayers && isNotOpen) {
            uint256 randomNumber = generateRandomNumber();
            uint256 winnerIndex = randomNumber % s_players.length;
            address payable winner = s_players[winnerIndex];

            s_recentWinner = winner;
            s_lastTimestamp = block.timestamp;
            s_raffleState = RaffleState.OPEN;
            s_players = new address payable[](0);

            emit PickWinner(winner, address(this).balance);

            (bool success, ) = winner.call{value: address(this).balance}("");
            if (!success) {
                revert Raffle__ETHTransferError();
            }

        } else {
            revert Raffle__CannotPickWinnerYet();
        }
    }

    // ---- getters ---- //
    function getPlayers() public view returns(uint256) {
        return s_players.length;
    }

    function getRecentWinner() public view returns(address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns(RaffleState) {
        return s_raffleState;
    }
}