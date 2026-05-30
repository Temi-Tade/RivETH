.PHONY: all test deploy

install:
	@npm install

%:
	@solc contracts/$*.sol --abi --bin -o ./artifacts --overwrite

update:
	@./UpdateRivETH