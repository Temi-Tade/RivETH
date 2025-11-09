// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TicketShop {
    // users send ETH
    // contract mint tickets upon receiving ETH
    // tickets are minted to addys that sent the ETH
    // ticket owners can send tickets to other addys
    // ticket can only be used once, after using them, they should be burnt

    string public name;
    string public symbol;
    address public owner;
    uint256 public totalTickets;
    uint256 internal nextTicketId;
    uint256 public constant MINIMUM_TICKET_PRICE = 1e15 wei; // 0.001eth

    struct Ticket {
        address owner;
        uint256 ticketId;
        uint256 mintedOn;
        uint256 validity; // in seconds
    }

    mapping (uint256 ticketId => Ticket) public tickets;

    event UseTicket(address indexed owner, uint256 ticketId);
    event MintTicket(address indexed owner, uint256 indexed ticketId);
    event TransferTicketOwnership(uint256 indexed ticketId, address indexed newOwner);

    error TicketShop_NotEnoughEther(string);
    error TicketShop_NotTicketOwner(string);
    error TicketShop_InvalidTicket(string);

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function mintTicket() public payable {
        if (msg.value != MINIMUM_TICKET_PRICE) {
            revert TicketShop_NotEnoughEther("Ticket price is 0.001 ETH");
        }

        nextTicketId++; 

        Ticket memory newTicket = Ticket({
            owner: msg.sender,
            ticketId: nextTicketId,
            mintedOn: block.timestamp,
            validity: 30 days
        });

        totalTickets += 1;
        tickets[nextTicketId] = newTicket;
        emit MintTicket(msg.sender, nextTicketId);
    }

    function transferOwnership(uint256 _ticketId, address to) public isOwner(_ticketId) isValid(_ticketId) returns(bool) {
        require(msg.sender != to, "You already own this ticket");
        tickets[_ticketId].owner = to;
        emit TransferTicketOwnership(_ticketId, to);

        return true;
    }

    function isTicketValid(uint256 _ticketId) public view returns(bool ticketValidity) {
        uint256 timeDifference = block.timestamp - tickets[_ticketId].mintedOn;

        if (timeDifference > tickets[_ticketId].validity || tickets[_ticketId].owner == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function useTicket(uint256 _ticketId) public isOwner(_ticketId) isValid(_ticketId) returns(bool) {
        // check that ticket to be used exists/is valid
        require(tickets[_ticketId].owner != address(0), "Ticket does not exist");
        
        // burn used ticket
        totalTickets -= 1;
        tickets[_ticketId].owner = address(0);
        emit UseTicket(msg.sender, _ticketId);

        return true;
    }

    modifier isOwner(uint256 _ticketId) {
        if (tickets[_ticketId].owner != msg.sender) {
            revert TicketShop_NotTicketOwner("You do not own this ticket");
        }
        _;
    }

    modifier isValid(uint256 _ticketId) {
        bool ticketValidity = isTicketValid(_ticketId);

        if (!ticketValidity) {
            totalTickets -= 1;
            tickets[_ticketId].owner = address(0);
            revert TicketShop_InvalidTicket("Ticket not valid");
        }
        _;
    }

    function withdraw() public {
        require(owner == msg.sender, "Caller is not owner");
        (bool success,) = msg.sender.call{value: address(this).balance}("");

        require(success, "Withdraw failed");
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    receive() external payable {
        mintTicket();
    }

    fallback() external payable {
        mintTicket();
    }
}