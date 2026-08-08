# RivETH

> A local, web-based, open-source Ethereum smart contract development toolkit featuring the **RivETHScan** block explorer, automated test scripting, and multi-tab orchestration.

---

<p align="center">
  <img src="https://img.shields.io/badge/Latest%20Release-v1.7.1-6366f1?style=for-the-badge&logo=github&logoColor=white" alt="Latest Release" />
  <a href="https://www.alchemy.com/dapps/riveth">
    <img src="https://img.shields.io/badge/Alchemy-Listed-0052FF?style=for-the-badge&logo=alchemy&logoColor=white" alt="Listed in Alchemy" />
  </a>
</p>

---

## Key Features

* **RivETHScan Block Explorer:** Inspect transactions, blocks, and deployed contracts locally with a built-in block explorer interface.
* **Custom Automated Scripting:** Write and execute automated contract workflows using `.riveth` files.
* **Injected Wallet & Provider Support:** Seamlessly connect and interact with MetaMask, Frame, or local Hardhat provider instances.
* **Multi-Tab Orchestration:** Monitor logs, run scripts, and inspect state changes across multiple browser tabs simultaneously.
* **Zero-Friction Local Pipeline:** Rapidly compile, deploy, and redeploy contracts directly from your terminal workspace.
* **Alchemy Verified:** Official listing featured on the [Alchemy dApp Store](https://www.alchemy.com/dapps/riveth).

---

## Prerequisites

Ensure you have the following installed before getting started:

1. **[Node.js](https://nodejs.org/)** (Latest LTS or Current)
2. **VS Code Extensions** *(Verify publisher names before installing)*:
* **Solidity** (by *Nomic Foundation*)
* **Live Server** (by *Ritwick Dey*)


> **Note:** `solc` (Solidity compiler) and `hardhat` (local Blockchain node provider) will be installed automatically alongside project dependencies.

---

## Quick Start

### 1. Download & Initialize

Open your terminal (or Git Bash on Windows) and run:

```bash
# Create and enter your workspace directory
mkdir solidity-smart-contract-practice && cd solidity-smart-contract-practice

# Download and extract the latest RivETH codebase
curl -L -O https://github.com/Temi-Tade/RivETH/archive/refs/heads/main.zip --output RivETH.zip && unzip RivETH.zip -d temp && mv temp/RivETH-main/* . && rm -rf temp RivETH.zip

# Navigate into the project folder and run the setup script
cd RivETH
chmod +x setup
./setup

```
This will install dependencies, and spin up the local Blockchain node.

### 2. Compile Contracts

In a **separate terminal window** within your project directory, compile your Solidity contract using either command (do not include the `.sol` extension):

```bash
./compile [FILE_NAME]
# OR
make [FILE_NAME]

```

*Example:* `./compile MyContract` or `make MyContract`

### 3. Launch Web App & Block Explorer

Start the **VS Code Live Server** extension to open the RivETH dashboard interface directly in your browser.

The official documentation is linked below for further reading.
---

## Usage Guidelines & Best Practices

* **Contract Naming:** It is recommended that your filename matches your contract name (e.g., `MyContract.sol` containing `contract MyContract { ... }`).
* **Sample Contracts:** Sample Solidity files are available in the `contracts/` directory for reference. *(These are for testing/learning only - do not use in production).*
* **Artifacts Folder:** Do not manually edit or write files to `artifacts/`. The solidity compiler will automatically populate this directory.
* **Redeploying Changes:** After updating your Solidity source code and recompiling, simply click the **Load** button in the web UI to fetch the latest ABI and bytecode before redeploying.

---

## Updating RivETH

RivETH receives frequent updates, bug fixes, and performance patches. To update your local setup to the latest release, run either command in your project root:

```bash
make update
# OR
./UpdateRivETH

```

---

## Contributing

Contributions are welcome! To contribute:

1. **Fork** the repository.
2. **Clone** your fork locally.
3. **Open an Issue** detailing the feature, fix, or enhancement you plan to work on.
4. **Create a branch** and commit your changes.
5. **Open a Pull Request** referencing your issue for review.
