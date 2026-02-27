// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "./ERC20.sol";

/// @title MultiSigWallet Contract
/// @author Temiloluwa Akintade
/// @notice A smart contract wallet that executes transactions 
/// when a certain threshold of unique signers has been reached
/// @dev Structs and mappings are used to manage transactions and signers

contract MultiSigWallet {
    // deploy contract and set signers and threshold
    // manage signers
    // manage threshold
    // propose txs
    // sign txs
    // exec txs
    // roles????
    error MultiSigWallet__DuplicateSigner(address);
    error MultiSigWallet__ThresholdError();
    // error MultiSigWallet__NotOwner();
    error MultiSigWallet__SenderIsNotASigner(address);
    error MultiSigWallet__SignerExists(address);
    error MultiSigWallet__MinimumSignersReached();
    error MultiSigWallet__CannotRemoveOwner();
    error MultiSigWallet__SignerDoesNotExist(address);
    error MultiSigWallet__TransactionDoesNotExist(uint256);
    error MultiSigWallet__TransactionHasBeenExecuted(uint256);
    error MultiSigWallet__SignerHasSignedTransaction(uint256);
    error MultiSigWallet__SignerHasNotSignedTransaction(uint256);
    error MultiSigWallet__TransactionHasMaxSigners(uint256);
    error MultiSigWallet__InvalidTransactionNonce(uint256);
    error MultiSigWallet__ThresholdUpdateError(uint256);
    error MultiSigWallet__SenderIsNotProposer(address);
    error MultiSigWallet__ERC20TokenAlreadyAdded(ERC20);

    event AddSigner(address indexed signer);
    event RemoveSigner(address indexed signer);
    event ChangeSigner(address indexed oldSigner, address indexed newSigner);
    event ProposeTransaction(address indexed proposer, uint256 indexed _nonce);
    event SignTransaction(address indexed signer, uint256 indexed _nonce);
    event ExecTransaction(address indexed executor, uint256 indexed _nonce);
    event RevokeSignature(address indexed revoker, uint256 indexed _nonce);
    event RejectTransaction(address indexed signer, uint256 indexed _nonce);

    /// @notice deploys the MultiSig
    /// @dev sets the signers and threshold at deployment time
    /// @param _signers unique signers that can propose and sign txs
    /// @param _threshold the minimum number of signers that need
    /// to sign a tx in order to execute it
    constructor(/*string memory name,*/address[] memory _signers, uint256 _threshold) {
        s_signers.push(msg.sender); // add deployer as a signer
        s_indexOfSigner[msg.sender] = 0;
        i_multiSigOwner = msg.sender; // set deployer as owner
        s_threshold = _threshold; // set threshold

        // a mapping can be used to store each signer's index,
        // in a case where there are many signers, managing them
        // via an indexed is scalable and gas-effiecient.

        // add all signers passed in constructor
        for (uint256 i = 0; i < _signers.length; i++) {
            s_signers.push(_signers[i]);
            s_indexOfSigner[_signers[i]] = i + 1;
        }

        // check for duplicate signers
        for (uint256 i = 0; i < s_signers.length - 1; i++) {
            for (uint256 j = i + 1; j < s_signers.length; j++) {
                if (s_signers[i] == s_signers[j]) {
                    revert MultiSigWallet__DuplicateSigner(s_signers[i]);
                }
            }
        }

        // check if threshold <= number of signers
        if (s_threshold > s_signers.length || s_threshold == 0) {
            revert MultiSigWallet__ThresholdError();
        }
    }

    modifier multiSigTransaction(uint256 _nonce, uint256 _value, bytes memory _calldata, address _targetAddress) {
        _initMultiSigTransaction(_nonce, _value, _calldata, _targetAddress);
        _;
    }

    /////////////////////////
    // storage variables ////
    ////////////////// //////
    uint256 nonce; // unique sequential integer that represents a tx
    uint256 s_threshold; // minimum number of signatures required to execute tx

    address[] s_signers; 
    Transaction[] s_queue; // waiting room for txs to be executed
    Transaction[] s_transactions; // ensure queued and exec txs do not have the same nonce
    ERC20[] s_erc20Tokens;

    mapping(address signer => uint256 index) s_indexOfSigner;
    mapping(uint256 id => Transaction queuedTx) s_queuedTransaction; // a tx in `s-queue`
    mapping(uint256 id => Transaction tx) s_transaction; // getTransactionHash (via nonce)
    mapping(address signer => mapping(uint256 id => bool hasSigned)) s_hasSignedTransaction;
    mapping(address signer => mapping(uint256 nonce => uint256 signerIndex)) s_transactionSignerIndex; // track the index of each signer in a tx/queue
    mapping(ERC20 tokenAddress => uint256) s_erc20Token;

    struct Transaction {
        uint256 _txIndexInQueue;
        address _txProposer;
        uint256 _txNonce;
        bytes _txData;
        uint256 _txValue;
        address[] _txSigners;
        address _txExecutor;
        address _txTarget;
        bytes32 _txHash;
    }

    struct ERC20Token {
        ERC20 _tokenAddress;
        string _tokenName;
        string _tokenSymbol;
        uint256 _tokenDecimals;
        uint256 _tokenBalance;
    }

    address immutable i_multiSigOwner; // deployer of the multi sig ?? is this necessary
    uint256 constant MINIMUM_SIGNERS = 1;

    function _proposeTransaction(uint256 _nonce, uint256 _value, bytes memory _data, address _targetAddress) internal {
        // flow: propose tx -> add to queue -> sign txs -> update and check number of signers
        // upon every signing -> exec tx if treshold is reached -> check if nonce is in exec
        // -> move tx from queue to exec

        Transaction memory newTransaction = Transaction({
            _txIndexInQueue: s_queue.length,
            _txProposer: msg.sender,
            _txNonce: _nonce,
            _txData: _data,
            _txValue: _value,
            _txSigners: new address[](0), // array of address(0)s
            _txExecutor: address(0),
            _txTarget: _targetAddress,
            _txHash: bytes32(0)
        });

        s_queue.push(newTransaction);
        s_queuedTransaction[_nonce] = newTransaction;

        nonce = _nonce;
        nonce += 1;

        emit ProposeTransaction(msg.sender, _nonce);
    }

    function _initMultiSigTransaction(uint256 _nonce, uint256 _value, bytes memory _calldata, address _targetAddress) internal {
        uint256 indexOfSigner = s_indexOfSigner[msg.sender];

        if (_nonce >= nonce) {
            // msg.sender must be a signer to propose txs
            if (msg.sender != s_signers[indexOfSigner]) {
                revert MultiSigWallet__SenderIsNotASigner(msg.sender);
            }
            _proposeTransaction(_nonce, _value, _calldata, _targetAddress);
        } else if (s_queuedTransaction[_nonce]._txProposer == address(0)) {
            // _nonce < nonce but tx has been executed
            revert MultiSigWallet__InvalidTransactionNonce(_nonce);
        }
    }

    function _updateTransactionQueue(uint256 _nonce) internal {
        // remove tx from s_queue
        delete s_queue[s_queuedTransaction[_nonce]._txIndexInQueue];
        delete s_queuedTransaction[_nonce];
    }

    function _getERC20TokenBalances() internal view returns(ERC20Token[] memory) {
        ERC20Token[] memory _erc20TokensWithUpdatedBalances = new ERC20Token[](s_erc20Tokens.length);

        for (uint256 i = 0; i < s_erc20Tokens.length; i++) {
            _erc20TokensWithUpdatedBalances[i] = ERC20Token({
                _tokenAddress: s_erc20Tokens[i],
                _tokenName: ERC20(s_erc20Tokens[i]).name(),
                _tokenSymbol: ERC20(s_erc20Tokens[i]).symbol(),
                _tokenDecimals: ERC20(s_erc20Tokens[i]).decimals(),
                _tokenBalance: ERC20(s_erc20Tokens[i]).balanceOf(address(this))
            });
        }

        return _erc20TokensWithUpdatedBalances;
    }

    // should only owner/delegators manage signers????
    
    /// @notice add a new signer
    /// @dev add an address that does not already exist in `s_signers`
    /// @param _newSigner the new signer to add to `s_signers
    /// @param _threshold new threshold after adding new signer
    function addSigner(uint256 _nonce, address _newSigner, uint256 _threshold) public multiSigTransaction(_nonce, 0, abi.encodeWithSelector(this.addSigner.selector, _nonce, _newSigner, _threshold), address(this)) {
        // get index of signer
        uint256 indexOfSigner = s_indexOfSigner[_newSigner];
        if (indexOfSigner != 0 || (indexOfSigner == 0 && _newSigner == s_signers[indexOfSigner])) {
            revert MultiSigWallet__SignerExists(_newSigner);
        }

        if (
            _threshold < s_threshold ||
            _threshold > s_signers.length + 1 ||
            _threshold == 0
        ) {
            revert MultiSigWallet__ThresholdError();
        }

        if (s_queuedTransaction[_nonce]._txSigners.length >= s_threshold) {
            // check if _newSigner already exists
            s_signers.push(_newSigner);
            s_indexOfSigner[_newSigner] = s_signers.length - 1;
            s_threshold = _threshold;
            
            _updateTransactionQueue(_nonce);

            emit AddSigner(_newSigner);
        }
    }

    /// @notice remove a signer
    /// @dev remove an address that already exists in `s_signers`
    /// @param _signerToRemove signer to remove from `s_signers`
    /// @param _threshold new threshold after remving a signer
    function removeSigner(uint256 _nonce, address _signerToRemove, uint256 _threshold) public multiSigTransaction(_nonce, 0, abi.encodeWithSelector(this.removeSigner.selector, _nonce, _signerToRemove, _threshold), address(this)) {
        uint256 _lastSignerIndex = s_signers.length - 1; // index of last signer in s_signers
        uint256 _oldSignerIndex = s_indexOfSigner[_signerToRemove]; // index of _signerToRemove

        if (_signerToRemove == i_multiSigOwner) {
            revert MultiSigWallet__CannotRemoveOwner(); // revie.w cannot remove owner
        }

        // if _signerToRemove does not exist in s_signers,
        // s_indexOfSigner[_signerToRemove] => _oldSignerIndex returns 0,
        // s_signers[0] is the first signer (the Multisig owner/deployer/creator)
        // this checks to confirm if _signerToRemove exists in s_signers
        if (s_signers[_oldSignerIndex] != _signerToRemove) {
            revert MultiSigWallet__SignerDoesNotExist(_signerToRemove);
        }
        if (s_signers.length - 1 < MINIMUM_SIGNERS) {
            revert MultiSigWallet__MinimumSignersReached();
        }
        if (_threshold > s_signers.length - 1 || s_threshold == 0) {
            revert MultiSigWallet__ThresholdError();
        }

        if (s_queuedTransaction[_nonce]._txSigners.length >= s_threshold) {
            s_signers[_oldSignerIndex] = address(0); // replace _signerToRemove index with address(0)

            // swap last signer in s_signers with _signerToRemove
            s_signers[_oldSignerIndex] = s_signers[_lastSignerIndex];
            s_indexOfSigner[s_signers[_lastSignerIndex]] = _oldSignerIndex;
            
            s_signers.pop(); // remove last item in s_signers (_signerToRemove)
            s_indexOfSigner[_signerToRemove] = 0;

            s_threshold = _threshold;

            _updateTransactionQueue(_nonce);

            emit RemoveSigner(_signerToRemove);
        }
    }

    /// @notice Replace a signer with another signer, useful in situations where a signer has been compromised
    /// @dev Swap out an existing signer with a non-existent signer
    /// @param _signerToReplace signer to swap out
    /// @param _signerToAdd signer to swap in
    /// ? should threshold be changeable here??
    function swapSigner(uint256 _nonce, address _signerToReplace, address _signerToAdd) public multiSigTransaction(_nonce, 0, abi.encodeWithSelector(this.swapSigner.selector, _nonce, _signerToReplace, _signerToAdd), address(this)) {
        uint256 _oldSignerIndex = s_indexOfSigner[_signerToReplace]; // get index of signer to replace

        if (_signerToReplace == i_multiSigOwner) {
            revert MultiSigWallet__CannotRemoveOwner();
        }
        if (s_signers[_oldSignerIndex] != _signerToReplace) {
            revert MultiSigWallet__SignerDoesNotExist(_signerToReplace);
        }
        if (s_indexOfSigner[_signerToAdd] != 0 || _signerToAdd == i_multiSigOwner) {
            revert MultiSigWallet__SignerExists(_signerToAdd); 
        }

        if (s_queuedTransaction[_nonce]._txSigners.length >= s_threshold) {
            s_signers[_oldSignerIndex] = _signerToAdd; // add _signerToAdd to s_signers
            s_indexOfSigner[_signerToReplace] = 0; // reset _signerToReplace index
            s_indexOfSigner[_signerToAdd] = _oldSignerIndex; // set _signerToAdd index

            _updateTransactionQueue(_nonce);

            emit ChangeSigner(_signerToReplace, _signerToAdd);
        }
    }

    /// @notice update threshold required to execute a tx
    /// @dev new threshold must be <= `s_signers.length`
    /// @param _threshold new threshold
    function setThreshold(uint256 _nonce, uint256 _threshold) public multiSigTransaction(_nonce, 0, abi.encodeWithSelector(this.setThreshold.selector, _nonce, _threshold), address(this)) {
        if (
            _threshold == s_threshold ||
            _threshold > s_signers.length ||
            _threshold == 0
        ) {
            revert MultiSigWallet__ThresholdUpdateError(_threshold);
        }

        if (s_queuedTransaction[_nonce]._txSigners.length >= s_threshold) {
            // if length >= s_threshold???
            s_threshold =_threshold;
            _updateTransactionQueue(_nonce);
        }
    }

    function sendEther(uint256 _nonce, uint256 _value) public {
        _initMultiSigTransaction(_nonce, _value, abi.encodeWithSelector(this.sendEther.selector), address(0));
    }

    function transferERC20(uint256 _nonce, ERC20 _tokenAddress, address _to, uint256 _amount) public {
        _initMultiSigTransaction(
            _nonce,
            0,
            abi.encodeWithSelector(ERC20(_tokenAddress).transfer.selector, _to, _amount),
            address(_tokenAddress)
        );
    }

    function signTransaction(uint256 _nonce/*, bool _exec -> from frontend*/) public {
        // check if max signers has been reached
        if (s_queuedTransaction[_nonce]._txProposer == address(0)) {
           revert MultiSigWallet__TransactionDoesNotExist(_nonce); // tx does not exist or has been executed
        }
        if(s_hasSignedTransaction[msg.sender][_nonce]) {
            revert MultiSigWallet__SignerHasSignedTransaction(_nonce); // signer cannot sign same tx 2ce
        }
        if (s_queuedTransaction[_nonce]._txSigners.length == s_threshold) {
            revert MultiSigWallet__TransactionHasMaxSigners(_nonce);
        }
        if (s_signers[s_indexOfSigner[msg.sender]] != msg.sender) {
            revert MultiSigWallet__SignerDoesNotExist(msg.sender);
        }

        s_queuedTransaction[_nonce]._txSigners.push(msg.sender);
        s_hasSignedTransaction[msg.sender][_nonce] = true;
        s_transactionSignerIndex[msg.sender][_nonce] = s_queuedTransaction[_nonce]._txSigners.length - 1;

        emit SignTransaction(msg.sender, _nonce);
    }

    function execTransaction(uint256 _nonce) public payable {
        // checks
        if (s_queuedTransaction[_nonce]._txProposer == address(0)) {
            revert MultiSigWallet__TransactionDoesNotExist(_nonce);
        }
        if (s_transaction[_nonce]._txExecutor != address(0)) {
            revert MultiSigWallet__TransactionHasBeenExecuted(_nonce);
        }
        if (s_queuedTransaction[_nonce]._txSigners.length < s_threshold) {
            revert MultiSigWallet__ThresholdError();
        }
        if (s_signers[s_indexOfSigner[msg.sender]] != msg.sender) {
            revert MultiSigWallet__SignerDoesNotExist(msg.sender);
        }

        // effects
        s_queuedTransaction[_nonce]._txExecutor = msg.sender;
        s_queuedTransaction[_nonce]._txHash = keccak256(abi.encode(s_queuedTransaction[_nonce]._txProposer, msg.sender, address(this), _nonce));
        s_transaction[_nonce] = s_queuedTransaction[_nonce]; // set s_transaction
        s_transactions.push(s_queuedTransaction[_nonce]);

        emit ExecTransaction(msg.sender, _nonce);

        // interactions
        // use _txData to know if its sendEther or not
        if (bytes4(s_queuedTransaction[_nonce]._txData) == this.sendEther.selector) {
            require(msg.value == s_queuedTransaction[_nonce]._txValue, "Unequal msg.value");
            _updateTransactionQueue(_nonce);
        } else {
            // tx is an internal tx
            if (s_queuedTransaction[_nonce]._txTarget == address(this)) {
                bytes memory callData = s_queuedTransaction[_nonce]._txData;
                address targetAddress = s_queuedTransaction[_nonce]._txTarget;
                (bool success, ) = targetAddress.call(callData);
                require(success, "Tx execution error");

            } else {
                // make external call
                bytes memory callData = s_queuedTransaction[_nonce]._txData;
                address targetAddress = s_queuedTransaction[_nonce]._txTarget;
                
                _updateTransactionQueue(_nonce);
                (bool success, ) = targetAddress.call(callData);
                require(success, "Tx execution error");
            }
        }
    }

    function revokeSignature(uint256 _nonce) public {
        if (s_queuedTransaction[_nonce]._txProposer == address(0)) {
            // tx does not exist or has been executed
           revert MultiSigWallet__TransactionDoesNotExist(_nonce);
        }
        if (s_signers[s_indexOfSigner[msg.sender]] != msg.sender) {
            revert MultiSigWallet__SignerDoesNotExist(msg.sender);
        }
        if(!s_hasSignedTransaction[msg.sender][_nonce]) {
            // signer cannot revoke sign from a tx he has not signed
            revert MultiSigWallet__SignerHasNotSignedTransaction(_nonce); 
        }

        uint256 _signerIndex = s_transactionSignerIndex[msg.sender][_nonce];
        address[] memory _txSigners = s_queuedTransaction[_nonce]._txSigners;
        address _lastSigner = _txSigners[_txSigners.length - 1];

        s_queuedTransaction[_nonce]._txSigners[_signerIndex] = _lastSigner; // swap revoking signer with last signer
        s_queuedTransaction[_nonce]._txSigners.pop();
        s_hasSignedTransaction[msg.sender][_nonce] = false;
        delete s_transactionSignerIndex[msg.sender][_nonce]; 
        s_transactionSignerIndex[_lastSigner][_nonce] = _signerIndex; // set tx signing index of new signer to revoker's index

        emit RevokeSignature(msg.sender, _nonce);
    }

    function rejectTransaction(uint256 _nonce) public {
        if (s_queuedTransaction[_nonce]._txProposer == address(0)) {
            // tx does not exist or has been executed
           revert MultiSigWallet__TransactionDoesNotExist(_nonce);
        }
        if (s_signers[s_indexOfSigner[msg.sender]] != msg.sender) {
            revert MultiSigWallet__SignerDoesNotExist(msg.sender);
        }
        if (s_queuedTransaction[_nonce]._txProposer != msg.sender) {
            revert MultiSigWallet__SenderIsNotProposer(msg.sender);
        }

        // reset signer status
        // find a better way to do this, a loop can be expensive for large arrays
        address[] memory _txSigners = s_queuedTransaction[_nonce]._txSigners;
        if (_txSigners.length > 0) {
            for (uint256 i = 0; i < _txSigners.length; i++) {
                if (s_hasSignedTransaction[_txSigners[i]][_nonce]) {
                    s_hasSignedTransaction[_txSigners[i]][_nonce] = false;
                }
            }
        }

        nonce -= 1;
        _updateTransactionQueue(_nonce);

        emit RejectTransaction(msg.sender, _nonce);
    }

    function addERC20Token(ERC20 _tokenAddress) public {
        if (s_erc20Tokens.length >= 1 &&
            address(s_erc20Tokens[s_erc20Token[_tokenAddress]]) == address(_tokenAddress)
        ) {
            revert MultiSigWallet__ERC20TokenAlreadyAdded(_tokenAddress);
        }

        s_erc20Token[_tokenAddress] = s_erc20Tokens.length;
        s_erc20Tokens.push(_tokenAddress);
    }

    /* set roles -> proposer, signer
    ** events
    ** modifiers
    ** check exec when threshold is updated
    ** only owner can set roles
    ** let any signer add/remove/change signers
    ** integrate tokens and protocols
    */

    //////////////////////
    /// view functions ///
    //////////////////////
    function getMultiSigOwner() external view returns(address) {
        return i_multiSigOwner;
    }

    function getThreshold() external view returns(uint256) {
        return s_threshold;
    }

    function getNumberOfSigners() external view returns(uint256) {
        return s_signers.length;
    }

    function getSignerIndex(address _signer) external view returns(uint256) {
        return s_indexOfSigner[_signer];
    }

    function getSigner(uint256 _signerIndex) external view returns(address) {
        return s_signers[_signerIndex];
    }

    function getNextNonce() external view returns(uint256) {
        return nonce;
    }

    function getQueuedTransaction(uint256 _nonce) external view returns(Transaction memory) {
        return s_queuedTransaction[_nonce];
    }

    function getTransaction(uint256 _nonce) external view returns(Transaction memory) {
        return s_transaction[_nonce];
    }

    function getSignerStatus(address _signer, uint256 _nonce) external view returns(bool) {
        return s_hasSignedTransaction[_signer][_nonce];
    }

    function getSignerIndexInTransaction(address _signer, uint256 _nonce) external view returns(uint256) {
        return s_transactionSignerIndex[_signer][_nonce];
    }
    // function

    function getERC20Token(ERC20 _tokenAddress) external view returns(ERC20Token memory) {
        return ERC20Token({
            _tokenAddress: _tokenAddress,
            _tokenName: ERC20(_tokenAddress).name(),
            _tokenSymbol: ERC20(_tokenAddress).symbol(),
            _tokenDecimals: ERC20(_tokenAddress).decimals(),
            _tokenBalance: ERC20(_tokenAddress).balanceOf(address(this))
        });
    }

    function getAllERC20Tokens() external view returns(ERC20Token[] memory) {
        return _getERC20TokenBalances();
    }
}