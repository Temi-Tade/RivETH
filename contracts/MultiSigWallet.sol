// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract MultiSigWallet {
    error MultiSigWallet__DuplicateSigner(address);
    error MultiSigWallet__DeployerIsDefaultSigner(address);

    constructor(address[] memory _signers, uint256 _numberOfConfirmations) {
        s_signers.push(msg.sender);

        for (uint256 i = 0; i < _signers.length; i++) {
            if (msg.sender == _signers[i]) {
                revert MultiSigWallet__DeployerIsDefaultSigner(msg.sender);
            }

            for (uint256 j = _signers.length - 1; j > 0; j++) {
                if (_signers[i] == _signers[j]) {
                    revert();
                }
            }

            s_signers.push(_signers[i]);
        }

        s_numberOfConfirmations = _numberOfConfirmations;
    }

    address[] public s_signers;
    uint256 public s_numberOfConfirmations;
}