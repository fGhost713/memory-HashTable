import Blob "mo:base/Blob";
import HashTableTypes "../types/hashTableTypes";
import StableTrieMap "mo:StableTrieMap";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Region "mo:base/Region";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Binary "../helpers/binary";
import Itertools "mo:itertools/Iter";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import { MemoryRegion } "mo:memory-region";
import libIndexMapping "libIndexMapping";

module {

    private type KeyInfo = HashTableTypes.KeyInfo;
    private type MemoryStorage = HashTableTypes.MemoryStorage;
    private func nat32Identity(n : Nat32) : Nat32 { return n };

    public func get_memory_addresses(key : Blob, memoryStorage : MemoryStorage) : ?(Nat64 /*key info address*/, Nat64 /*wrappedBlob address*/) {

        let keySize = Nat64.fromNat(key.size());
        let valuesList = libIndexMapping.get_values(key, memoryStorage);
        let listSize : Nat = List.size(valuesList);
        if (listSize == 0) {
            return null;
        };

        for (index in Iter.range(0, listSize -1)) {
            let adressOrNull = List.get(valuesList, index);
            switch (adressOrNull) {
                case (?foundAddress) {

                    let sizeOfKeyBlob = Region.loadNat64(memoryStorage.memory_region.region, foundAddress + 8);
                    if (sizeOfKeyBlob == keySize) {
                        let keyAsBlob = Region.loadBlob(memoryStorage.memory_region.region, foundAddress +24, Nat64.toNat(sizeOfKeyBlob));
                        if (Blob.equal(keyAsBlob, key) == true) {
                            let wrappedBlobMemoryAddress = Region.loadNat64(memoryStorage.memory_region.region, foundAddress + 16);
                            return Option.make((foundAddress, wrappedBlobMemoryAddress));
                        };
                    };
                };
                case (_) {
                    // do nothing
                };

            };
        };

        return null;

    };

    // Update the wrappedBlob-memory-Adress
    public func update_wrappedBlob_address(
        memoryStorage : MemoryStorage,
        keyInfoAddress : Nat64,
        wrappedBlobAddress : Nat64,
    ) {
        let memoryOffsetWrappedBlobAddress : Nat64 = keyInfoAddress + 16;
        Region.storeNat64(memoryStorage.memory_region.region, memoryOffsetWrappedBlobAddress, wrappedBlobAddress);
    };

    // Delete keyinfo by memory address
    public func delete_keyinfo(memoryStorage : MemoryStorage, keyInfoAddress : Nat64) {

        let keyInfoSize : Nat64 = Region.loadNat64(memoryStorage.memory_region.region, keyInfoAddress);
        
        // Deleting by giving the memory free
        MemoryRegion.deallocate(memoryStorage.memory_region, Nat64.toNat(keyInfoAddress), Nat64.toNat(keyInfoSize));
    };

};
