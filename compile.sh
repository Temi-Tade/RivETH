## command line script to run the solidity compiler
## $1 - first command-line argument, points to the solidity file to be compiled 

#!/bin/bash
solc contracts/$1 --abi --bin -o ./artifacts --overwrite    