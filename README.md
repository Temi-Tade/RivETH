# RivETH

## _A local, web-based Ethereum Smart Contract development toolkit._
### Requirements
- NodeJS. Download <a href="https://nodejs.org/en/download/current">here</a>
- Hardhat. (Will be installed alongside dependencies)
- Solidity compiler (solc). Run <code>npm install -g solc</code>
- Solidity VSCode Extension - for syntax highlighting and code completion
- VSCode Live Server Extension by Ritwick Dey.
**_Verify publishers before installing any extension._**

### Set up
- In your VSCode terminal, clone RivETH's GitHub repo. <pre>curl -L -0 https://github.com/Temi-Tade/RivETH/archive/refs/heads/main.zip --output RivETH.z
ip && unzip RivETH.zip -d temp && mv temp/RivETH-main/* . && rm -rf temp RivETH.zip
</pre>
- Navigate to the <code>RivETH</code> folder. <code>cd RivETH</code> and open it on VSCode.
- Install dependencies: <pre>npm install</pre>
- In the <code>RivETH</code> directory in your terminal, start a local hardhat node:<pre>npx hardhat node</pre>
- In a separate terminal, compile the smart contract's solidity code:<pre>solc [FILE_NAME].sol --abi --bin -o ./artifacts/</pre>Replace <code>[FILE_NAME]</code> with the name of the file you want to compile.
- Start VSCode live server extension to open RivETH in your browser.

### Notes
- You can find pre-written solidity smart contracts in the <code>contracts/</code> folder. Note that these contracts have not been reviewed and are not to be used in production.
- Do not save or write any file to the <code>artifacts/</code> folder. The solidity compiler will automatically write files to this folder.
- Use the same name for the solidity file and contract (e.g. <code>MyContract.sol</code> and <code>contract MyContract{...}</code>).