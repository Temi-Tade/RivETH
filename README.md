# RivETH

## _A local, web-based, open source Ethereum Smart Contract development toolkit._
### Requirements
- NodeJS. Download <a href="https://nodejs.org/en/download/current">here</a>
- Hardhat.
- Solidity compiler (solc).
- Solidity VSCode Extension - for syntax highlighting and code completion
- VSCode Live Server Extension by Ritwick Dey.

**_Solc and Hardhat will be installed alongside the dependencies_**

**_Verify publishers before installing any extension._**

### Set up
- In your VSCode terminal, clone RivETH's GitHub repo. <pre>curl -L -0 https://github.com/Temi-Tade/RivETH/archive/refs/heads/main.zip --output RivETH.z
ip && unzip RivETH.zip -d temp && mv temp/RivETH-main/* . && rm -rf temp RivETH.zip
</pre>
- Navigate to the <code>RivETH</code> folder. <code>cd RivETH</code> and open it on VSCode.
- Install dependencies: <pre>npm install</pre>
- In the <code>RivETH</code> directory in your terminal, start a local hardhat node:<pre>npx hardhat node</pre>
- In a separate terminal and in your working directory, compile the smart contract's solidity code:<pre>./compile.sh [FILE_NAME].sol</pre>Replace <code>[FILE_NAME]</code> with the name of the file you want to compile.
- Start VSCode live server extension to open RivETH in your browser.

### Notes
- You can find pre-written solidity smart contracts in the <code>contracts/</code> folder. Note that these contracts have not been reviewed and are not to be used in production.
- Do not save or write any file to the <code>artifacts/</code> folder. The solidity compiler will automatically write files to this folder.
- Use the same name for the solidity file and contract (e.g. <code>MyContract.sol</code> and <code>contract MyContract{...}</code>).

### How to Contribute
RivETH is open source, you can help improve it by contributing. To contribute:
- Create a fork of the main repo.
- Clone your forked repo.
- Create an issue with the specific bug fix/change/feature you want to make/add.
- Work on your bug fix/change/feature and push your changes to the forked repo.
- Create a pull request with the bug fix/change/feature you worked on.
- Your PR will be reviewed and then merged if deemed fit.