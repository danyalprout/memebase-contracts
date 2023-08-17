include .env

.PHONY: deploy-drake
deploy-drake:
	forge create --rpc-url https://goerli.base.org \
        --constructor-args $(OWNER_ADDRESS) 100 "Drake Hotline Bling" "MDHB" \
        --private-key $(DEPLOYER_KEY) \
        --chain 85431 \
        --verifier-url https://api-goerli.basescan.org/api \
        --verify \
        --deny-warnings \
        src/MemebaseCollection.sol:MemebaseCollection

.PHONY: deploy-distracted-bf
deploy-distracted-bf:
	forge create --rpc-url https://goerli.base.org \
        --constructor-args $(OWNER_ADDRESS) 100 "Distracted Boyfriend" "MDB" \
        --private-key $(DEPLOYER_KEY) \
        --chain 85431 \
        --verifier-url https://api-goerli.basescan.org/api \
        --verify \
        --deny-warnings \
        src/MemebaseCollection.sol:MemebaseCollection

.PHONY: deploy-two-buttons
deploy-two-buttons:
	forge create --rpc-url https://goerli.base.org \
        --constructor-args $(OWNER_ADDRESS) 100 "Two Buttons" "MTB" \
        --private-key $(DEPLOYER_KEY) \
        --chain 85431 \
        --verifier-url https://api-goerli.basescan.org/api \
        --verify \
        --deny-warnings \
        src/MemebaseCollection.sol:MemebaseCollection

.PHONY: deploy-doge
deploy-doge:
	forge create --rpc-url https://goerli.base.org \
		--constructor-args $(OWNER_ADDRESS) 100 "Buff Doge vs. Cheems" "MDVC" \
		--private-key $(DEPLOYER_KEY) \
		--chain 85431 \
		--verifier-url https://api-goerli.basescan.org/api \
		--verify \
		--deny-warnings \
		src/MemebaseCollection.sol:MemebaseCollection

.PHONY: deploy-batman
deploy-batman:
	forge create --rpc-url https://goerli.base.org \
		--constructor-args $(OWNER_ADDRESS) 100 "Batman Slapping Robin" "MBSR" \
		--private-key $(DEPLOYER_KEY) \
		--chain 85431 \
		--verifier-url https://api-goerli.basescan.org/api \
		--verify \
		--deny-warnings \
		src/MemebaseCollection.sol:MemebaseCollection

.PHONY: check
check:
	forge fmt
	forge test -vvv

.PHONY: test-name
test-name:
	cast call --chain 85431  --rpc-url https://goerli.base.org  0x2434cDA21B80863b3f356B6446271cf62e1c1d89 "name() (string)"
