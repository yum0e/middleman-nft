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
   #[endpoint(withdrawBalance)]
   fn withdraw_balance(&self) {
       let caller = self.blockchain().get_caller();
       let sc_balance = self.blockchain().get_sc_balance(&TokenIdentifier::egld(), 0);
       
       self.send().direct_egld(
           &caller,
           &sc_balance,
           &[]
       );
   }

   // endpoint 

   #[payable("*")]
   #[endpoint(createOffer)]
   fn create_offer(
       &self,
       #[payment_token] token_id: TokenIdentifier, // the collection the nft_holder wants to sell
       #[payment_nonce] nonce: u64, // the nonce of the nft of the collection
       spender: ManagedAddress, // the address that will pay
       amount: BigUint, // amount to pay for the spender
    ) -> SCResult<u64> {
        let caller = self.blockchain().get_caller();
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

    #[endpoint(deleteOffer)]
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

    #[payable("*")]
    #[endpoint(acceptOffer)]
    fn accept_offer(
        &self,
        #[payment_token] token_id: TokenIdentifier,
        #[payment_amount] egld_amount: BigUint,
        id: u64
    ) -> SCResult<u64> {
        let caller = self.blockchain().get_caller();
        let mut offer = self.offers_with_id(&id).get();
        require!(offer.spender == caller, "You are not the spender designated for this offer");
        require!(token_id.is_egld(), "Only pay with egld");
        require!(offer.status == Status::Submitted, "Offer deleted or completed");
        require!(egld_amount == offer.amount, "Incorrect egld amount");

        // fees of 2% 
        let big_amount = egld_amount * BigUint::from(98u64);
        let real_amount = big_amount / BigUint::from(100u64);

        // send egld to previous holder
        self.send().direct_egld(
            &offer.nft_holder,
            &real_amount,
            &[]
        );

        // send the nft to the caller
        self.send().direct(
            &caller,
            &offer.token_id,
            offer.nonce,
            &BigUint::from(1u64),
            &[]
        );
        // update status
        offer.status = Status::Completed;
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
