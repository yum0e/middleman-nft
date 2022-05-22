WALLET_PEM="~/Elrond/secure-pems/yum0e-main.pem"
MY_ADDRESS="erd10q9pd9rhpx92y6ld6ag4758uwuc9meyfxfz36q5ez2eelxjy35dsnvt5dy"

PROXY="https://gateway.elrond.com"
CHAIN="1"
ADDRESS=$(erdpy data load --key=address-mainnet)
DEPLOY_TRANSACTION=$(erdpy data load --key=deployTransaction-mainnet)

BYTECODE="./middleman/output/middleman.wasm"

deploy() {
    erdpy --verbose contract deploy --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --send \
    --outfile="deploy-mainnet.interaction.json" || return

    TRANSACTION=$(erdpy data parse --file="deploy-mainnet.interaction.json" --expression="data['emitted_tx']['hash']")
    ADDRESS=$(erdpy data parse --file="deploy-mainnet.interaction.json" --expression="data['emitted_tx']['address']")

    erdpy data store --key=address-mainnet --value=${ADDRESS}
    erdpy data store --key=deployTransaction-mainnet --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgrade() {
    erdpy --verbose contract upgrade ${ADDRESS} --bytecode=${BYTECODE} --recall-nonce --metadata-payable \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=50000000 \
    --outfile="deploy-mainnet.interaction.json" \
    --send || return
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
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getOffersTo" --arguments $spender
}

getNbSubmittedFor() {
    spender="0x$(erdpy wallet bech32 --decode erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5)"
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getNbSubmittedFor" --arguments $spender
}
