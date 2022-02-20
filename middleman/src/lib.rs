#![no_std]

elrond_wasm::imports!();
elrond_wasm::derive_imports!();
use crate::elrond_codec::TopEncode;

#[derive(TypeAbi, NestedEncode, NestedDecode, TopEncode, TopDecode, PartialEq)]
pub enum Status {
    Submitted,
    Completed,
    Deleted
}

#[derive(TypeAbi, TopEncode, TopDecode)]
pub struct Offer<M: ManagedTypeApi> {
    pub id: u64,
    pub spender: ManagedAddress<M>,
    pub nft_holder: ManagedAddress<M>,
    pub amount: BigUint<M>,
    pub token_id: TokenIdentifier<M>,
    pub nonce: u64,
    pub status: Status
}

#[elrond_wasm::contract]
pub trait Middleman {

   #[init]
   fn init(&self) -> SCResult<()> {
       self.offers_count().set_if_empty(&1u64);
       Ok(())
   }

   // only-owner

   #[only_owner]
   #[view(withdraw)]
   fn withdraw_nft(
       &self,
       token_id: TokenIdentifier,
       nonce: u64
   ) -> SCResult<()> {
       let caller = self.blockchain().get_caller();
       self.send().direct(
           &caller,
           &token_id,
           nonce,
           &BigUint::from(1u64),
           &[]
       );
       Ok(())
   }

   // view 

   #[payable("*")]
   #[view(createOffer)]
   fn create_offer(
       &self,
       spender: ManagedAddress, // the address that will pay
       amount: BigUint, // amount to pay for the spender
       #[payment_token] token_id: TokenIdentifier, // the collection the nft_holder wants to sell
       #[payment_nonce] nonce: u64, // the nonce of the nft of the collection
    ) -> SCResult<u64> {
        let caller = self.blockchain().get_caller();
        require!(self.blockchain().get_esdt_balance(
            &caller,
            &token_id,
            nonce
        ) <= 0 , "You don't own the nft");
        require!(nonce > 0, "transfer only nft");
        require!(amount >= 0, "The amount specified is below zero");

        // creation of the offer and storage
        
        let id = self.offers_count().get();
        self.offers_from(&caller).update(|vec| vec.push(id));
        self.offers_to(&spender).update(|vec| vec.push(id));

        self.offers_count().set(&id + 1);
        let offer = Offer {
            id,
            spender,
            nft_holder: caller,
            amount,
            token_id,
            nonce,
            status: Status::Submitted
        };
        self.offers_with_id(&id).set(offer);
        Ok(id)
    }

    #[view(deleteOffer)]
    fn delete_offer(
        &self,
        id: u64 // id of the offer
    ) -> SCResult<u64> {
        let caller = self.blockchain().get_caller();
        let mut offer = self.offers_with_id(&id).get();
        require!(offer.nft_holder == caller, "You are not the creator of this offer");
        require!(offer.status == Status::Submitted, "Offer deleted or completed");
        self.send().direct(
            &caller,
            &offer.token_id,
            offer.nonce,
            &BigUint::from(1u64),
            &[]
        );
        offer.status = Status::Deleted;
        self.offers_with_id(&id).set(offer);
        Ok(id)
    }


   // storage

   #[view(getOffersCount)]
   #[storage_mapper("offers_count")] // know an offer details based on its id
   fn offers_count(&self) -> SingleValueMapper<u64>;

   #[view(getOffersWithId)]
   #[storage_mapper("offers_with_id")] // know an offer details based on its id
   fn offers_with_id(&self, id: &u64) -> SingleValueMapper<Offer<Self::Api>>;

   #[view(getOffersTo)]
   #[storage_mapper("offers_to")] // offers made to a certain address, we store the id of the offers
   fn offers_to(&self, address: &ManagedAddress) -> SingleValueMapper<ManagedVec<u64>>;

   #[view(getOffersFrom)]
   #[storage_mapper("offers_from")] // offers made from a certain address, we store the id of the offers
   fn offers_from(&self, address: &ManagedAddress) -> SingleValueMapper<ManagedVec<u64>>;
}