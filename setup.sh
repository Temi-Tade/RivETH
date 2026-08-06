wget -O /usr/local/bin/solc https://github.com/ethereum/solidity/releases/download/v0.8.36/solc-static-linux
chmod +x /usr/local/bin/solc
solc --version

npm install
npx hardhat node
