WALLET_PEM="~/Elrond/pems/yum0e1.pem"
OTHER_PEM="~/Elrond/pems/yum0e2.pem"
MY_ADDRESS="erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5"
OTHER_ADDRESS="erd1wx7h5rnyxre7avl5pkgj3c2fha9aknrwms8mspelfcapwvjac3vqncm7nm"

PROXY="https://devnet-gateway.elrond.com"
CHAIN="D"
ADDRESS=$(erdpy data load --key=address-devnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-devnet)

BYTECODE="./middleman/output/middleman.wasm"

deploy() {
    erdpy --verbose contract deploy --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --send \
    --outfile="deploy-devnet.interaction.json" || return

    TRANSACTION=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['emitted_tx']['hash']")
    ADDRESS=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['emitted_tx']['address']")

    erdpy data store --key=address-devnet --value=${ADDRESS}
    erdpy data store --key=deployTransaction-devnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    erdpy --verbose contract upgrade ${ADDRESS} --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --outfile="deploy-devnet.interaction.json" \
    --send || return
}

createOffer() {
    # $1 nonce
    spender="$(erdpy wallet bech32 --decode erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5)"
    spender2="$(erdpy wallet bech32 --decode erd1wx7h5rnyxre7avl5pkgj3c2fha9aknrwms8mspelfcapwvjac3vqncm7nm)" # yum0e2
    destination="$(erdpy wallet bech32 --decode $ADDRESS)"
    token_id="$(echo -n 'TST-9224fc' | xxd -p -u | tr -d '\n')"
    method="$(echo -n 'createOffer' | xxd -p -u | tr -d '\n')"

    erdpy --verbose tx new --receiver=${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=0 \
    --data="ESDTNFTTransfer@${token_id}@$1@01@${destination}@${method}@${spender2}@0DE0B6B3A7640000" \
    --send
}

deleteOffer() {
    # $1 offer id
    
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=0 \
    --function=deleteOffer \
    --arguments $1 \
    --send
}

acceptOffer() {
    # $1 offer id
    
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${OTHER_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=1000000000000000000 \
    --function=acceptOffer \
    --arguments $1 \
    --send
}

createOffer2() {
    # $1 nonce
    spender="$(erdpy wallet bech32 --decode erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5)"
    spender2="$(erdpy wallet bech32 --decode erd1wx7h5rnyxre7avl5pkgj3c2fha9aknrwms8mspelfcapwvjac3vqncm7nm)" # yum0e2
    destination="$(erdpy wallet bech32 --decode $ADDRESS)"
    token_id="$(echo -n 'TST-9224fc' | xxd -p -u | tr -d '\n')"
    method="$(echo -n 'createOffer' | xxd -p -u | tr -d '\n')"

    erdpy --verbose tx new --receiver=${OTHER_ADDRESS} --recall-nonce \
    --pem=${OTHER_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=0 \
    --data="ESDTNFTTransfer@${token_id}@$1@01@${destination}@${method}@${spender}@0DE0B6B3A7640000" \
    --send
}

deleteOffer2() {
    # $1 offer id
    
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${OTHER_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=0 \
    --function=deleteOffer \
    --arguments $1 \
    --send
}

acceptOffer2() {
    # $1 offer id
    
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=1000000000000000000 \
    --function=acceptOffer \
    --arguments $1 \
    --send
}

withdrawBalance() {
    erdpy --verbose contract call ${ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --value=0 \
    --function=withdrawBalance \
    --send
}

isEmpty() {
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="isEmpty" 
}

getOffersCount() {
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getOffersCount" 
}

getOffersWithId() {
    # $1 id of the offer
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getOffersWithId" --arguments $1
}

getOffersFrom() {
    spender="0x$(erdpy wallet bech32 --decode erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5)"
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getOffersFrom" --arguments $spender
}

getOffersTo() {
    spender="0x$(erdpy wallet bech32 --decode erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5)"
    spender2="0x$(erdpy wallet bech32 --decode erd1wx7h5rnyxre7avl5pkgj3c2fha9aknrwms8mspelfcapwvjac3vqncm7nm)" # yum0e2
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getOffersTo" --arguments $spender2
}
