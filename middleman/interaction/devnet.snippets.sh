WALLET_PEM="~/Elrond/pems/yum0e1.pem"
OTHER_PEM="~/Elrond/pems/yum0e2.pem"
MY_ADDRESS="erd1r5x47cf3mazmpxed9u237sk97a6jm059mna2y7s53zp705khtdks57t3lu"
OTHER_ADDRESS="erd1yq2v0rpt5h2lfa8ljkgu6mchrjvy6en3ywe2wfnnjun2rs4qu8nqalcfe5"

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

    TRANSACTION=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(erdpy data parse --file="deploy-devnet.interaction.json" --expression="data['contractAddress']")

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
    spender="0x$(erdpy wallet bech32 --decode erd1r5x47cf3mazmpxed9u237sk97a6jm059mna2y7s53zp705khtdks57t3lu)"
    spender2="0x$(erdpy wallet bech32 --decode erd1yq2v0rpt5h2lfa8ljkgu6mchrjvy6en3ywe2wfnnjun2rs4qu8nqalcfe5)" # yum0e2
    destination="0x$(erdpy wallet bech32 --decode $ADDRESS)"
    token_id="0x$(echo -n 'TTTT-75970f' | xxd -p -u | tr -d '\n')"
    method="0x$(echo -n 'createOffer' | xxd -p -u | tr -d '\n')"
    
    erdpy --verbose contract call ${MY_ADDRESS} --recall-nonce \
    --pem=${WALLET_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=5000000 \
    --value=0 \
    --function="ESDTNFTTransfer" \
    --arguments ${token_id} 01 01 ${destination} ${method} ${spender2} 0x0de0b6b3a7640000 \
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
    spender="0x$(erdpy wallet bech32 --decode erd1r5x47cf3mazmpxed9u237sk97a6jm059mna2y7s53zp705khtdks57t3lu)"
    spender2="0x$(erdpy wallet bech32 --decode erd1yq2v0rpt5h2lfa8ljkgu6mchrjvy6en3ywe2wfnnjun2rs4qu8nqalcfe5)" # yum0e2
    destination="0x$(erdpy wallet bech32 --decode $ADDRESS)"
    token_id="0x$(echo -n 'TTTT-75970f' | xxd -p -u | tr -d '\n')"
    method="0x$(echo -n 'createOffer' | xxd -p -u | tr -d '\n')"
    
    erdpy --verbose contract call ${OTHER_ADDRESS} --recall-nonce \
    --pem=${OTHER_PEM} \
    --chain=${CHAIN} --proxy=${PROXY} \
    --gas-limit=5000000 \
    --value=0 \
    --function="ESDTNFTTransfer" \
    --arguments ${token_id} 01 01 ${destination} ${method} ${spender} 0x0de0b6b3a7640000 \
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
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getOffersTo" --arguments $spender
}

getNbSubmittedFor() {
    spender="0x$(erdpy wallet bech32 --decode erd14q22erffu7r56mf26yx4erww9k0yresxmudte0etacl950ef7fys9qcus5)"
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getNbSubmittedFor" --arguments $spender
}

getCompletedOffers() {
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getCompletedOffers"
}

getLastCompletedOffers() {
    erdpy --verbose contract query ${ADDRESS} --proxy=${PROXY} --function="getLastCompletedOffers" --arguments=$1
}
