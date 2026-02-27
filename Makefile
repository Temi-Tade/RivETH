.PHONY: all test deploy

%:
	solc contracts/$*.sol --abi --bin -o ./artifacts --overwrite