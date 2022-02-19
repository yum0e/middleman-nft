#![no_std]

elrond_wasm::imports!();
elrond_wasm::derive_imports!();
use crate::elrond_codec::TopEncode;

#[derive(TypeAbi, TopEncode, TopDecode)]
pub struct Offer<M: ManagedTypeApi> {
    pub id: u64,
    pub spender: ManagedAddress<M>,
    pub nft_holder: ManagedAddress<M>,
    pub amount: BigUint<M>,
    pub token_id: TokenIdentifier<M>,
    pub nonce: u64,
}

#[elrond_wasm::contract]
pub trait Middleman {
   #[init]
   fn init(&self) -> SCResult<()> {
       self.number_of_offers().set(0u64);
       Ok(())
   }

   #[view(CreateOffer)]
   fn create_offer(
       &self,
       spender: ManagedAddress, // the address that will pay
       amount: BigUint, // amount to pay for the spender
       token_id: TokenIdentifier, // the collection the nft_holder wants to sell
       nonce: u64, // the nonce of the nft of the collection
    ) -> SCResult<u64> {
        let caller = self.blockchain().get_caller();
        require!(self.blockchain().get_esdt_balance(
            &caller,
            &token_id,
            nonce
        ) > 0 , "You don't own the nft");
        require!(amount >= 0, "The amount specified is below zero");
        let sc_address = self.blockchain().get_sc_address();
        //sending nft to the smart contract
        self.send().direct(
            &sc_address,
            &token_id,
            nonce,
            &amount,
            &[]
        );
        // creation of the offer and storage
        let id = self.number_of_offers().get();
        self.offers_from(&caller).update(|vec| vec.push(id));
        self.offers_to(&spender).update(|vec| vec.push(id));
        self.number_of_offers().update(|nb| *nb + 1);
        let offer = Offer {
            id,
            spender,
            nft_holder: caller,
            amount,
            token_id,
            nonce,
        };
        self.offers_with_id(&id).set(offer);
        Ok(id)
    }

   // storage

   #[view(getNbOffers)]
   #[storage_mapper("number_of_offers")] // know an offer details based on its id
   fn number_of_offers(&self) -> SingleValueMapper<u64>;

   #[view(getOffersWithId)]
   #[storage_mapper("offers_with_id")] // know an offer details based on its id
   fn offers_with_id(&self, id: &u64) -> SingleValueMapper<Offer<Self::Api>>;

   #[storage_mapper("offers_to")] // offers made to a certain address, we store the id of the offers
   fn offers_to(&self, address: &ManagedAddress) -> SingleValueMapper<ManagedVec<u64>>;

   #[storage_mapper("offers_from")] // offers made from a certain address, we store the id of the offers
   fn offers_from(&self, address: &ManagedAddress) -> SingleValueMapper<ManagedVec<u64>>;
}
