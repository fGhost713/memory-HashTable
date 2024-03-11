import Blob "mo:base/Blob";
import HashTableTypes "../types/hashTableTypes";
import StableTrieMap "mo:StableTrieMap";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Region "mo:base/Region";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import List "mo:base/List";
import Binary "../helpers/binary";
import Itertools "mo:itertools/Iter";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import libKeyInfo "libKeyInfo";
import { MemoryRegion } "mo:memory-region";
import libIndexMapping "libIndexMapping";

module {

    private type WrappedBlob = HashTableTypes.WrappedBlob;
    private type MemoryStorage = HashTableTypes.MemoryStorage;
    private type KeyInfo = HashTableTypes.KeyInfo;
    private func nat32Identity(n : Nat32) : Nat32 { return n };

    // Get the internal blob from WrappedBlob-Address
    public func get_internal_blob_from_memory(memoryStorage : MemoryStorage, address : Nat64) : Blob {

        let internalBlobSize = Nat64.toNat(Region.loadNat64(memoryStorage.memory_region.region, address + 8));
        let internalBlobAddress = address + 16;
        return Region.loadBlob(memoryStorage.memory_region.region, internalBlobAddress, internalBlobSize);
    };

    // Add or update value by key
    public func add_or_update(key : Blob, memoryStorage : MemoryStorage, blobToStoreOrUpdate : Blob) : Nat64 {

        let hashedKey = Blob.hash(key);
        let memoryAddressesOrNull = libKeyInfo.get_memory_addresses(key, memoryStorage);

        switch (memoryAddressesOrNull) {
            case (?memoryAddresses) {
                //key with value is already existing:

                let keyInfoAddress = memoryAddresses.0;
                let alreadyStoredWrappedBlobAddress = memoryAddresses.1;
                let totalSizeFromAlreadyStoredBlob : Nat64 = get_wrapped_blob_totalsize(memoryStorage, alreadyStoredWrappedBlobAddress);
                let blobToStoreOrUpdateSize : Nat = blobToStoreOrUpdate.size();
                var updatePossible : Bool = false;

                if (totalSizeFromAlreadyStoredBlob > 16) {

                    let freeSizeAvailable : Nat = Nat64.toNat(totalSizeFromAlreadyStoredBlob - 16);
                    if (blobToStoreOrUpdateSize <= freeSizeAvailable) {
                        updatePossible := true;
                    };
                };

                if (updatePossible == false) { // we need to insert completely new entries

                    //Mark the memory region as free:

                    MemoryRegion.deallocate(
                        memoryStorage.memory_region,
                        Nat64.toNat(alreadyStoredWrappedBlobAddress),
                        Nat64.toNat(totalSizeFromAlreadyStoredBlob),
                    );

                    // Add new item:
                    let storedAddress : Nat64 = create_and_add_new_wrappedblob_into_memory_Internal(memoryStorage, blobToStoreOrUpdate);

                    // We need to update keyinfo
                    libKeyInfo.update_wrappedBlob_address(memoryStorage, keyInfoAddress, storedAddress);
                    return storedAddress;

                } else {
                    let internalBlobSizeOffset : Nat64 = alreadyStoredWrappedBlobAddress + 8;
                    let internalBlobOffset : Nat64 = internalBlobSizeOffset + 8;

                    // Update the blob-size value
                    Region.storeNat64(
                        memoryStorage.memory_region.region,
                        internalBlobSizeOffset,
                        Nat64.fromNat(blobToStoreOrUpdateSize),
                    );

                    // Update the blob
                    Region.storeBlob(memoryStorage.memory_region.region, internalBlobOffset, blobToStoreOrUpdate);
                    return alreadyStoredWrappedBlobAddress;
                };
            };
            case (_) {   // The key was not used before
               
                let addresses = add_new_item_internal_and_update_key_mappings(key, memoryStorage, blobToStoreOrUpdate);

                return addresses.1;
            };
        };

        return 0;

    };

    // Delete entry by key
    public func delete(key : Blob, memoryStorage : MemoryStorage) {

        let memoryAddressesOrNull = libKeyInfo.get_memory_addresses(key, memoryStorage);

        switch (memoryAddressesOrNull) {
            case (?memoryAddresses) {

                let keyInfoAddress : Nat64 = memoryAddresses.0;
                let wrappedBlobAddress : Nat64 = memoryAddresses.1;

                libKeyInfo.delete_keyinfo(memoryStorage, keyInfoAddress);

                let wrappedBlobSize = get_wrapped_blob_totalsize(memoryStorage, wrappedBlobAddress);

                MemoryRegion.deallocate(
                    memoryStorage.memory_region,
                    Nat64.toNat(wrappedBlobAddress),
                    Nat64.toNat(wrappedBlobSize),
                );

                // Delete value from index-mappings-list
                libIndexMapping.remove_value(key, memoryStorage, keyInfoAddress);

            };
            case (_) {
                // do nothing
            };
        };
    };

    // Helper functions:

    // Add new entry (key and value). Assumption here is that the key was not existing before.
    private func add_new_item_internal_and_update_key_mappings(
        key : Blob,
        memoryStorage : MemoryStorage,
        blobToStore : Blob,
    ) : (Nat64 /* keyinfo-address*/, Nat64 /* stored wrapBlob address*/) {

        // store the blob into memory
        let valueStoredAddressNat64 : Nat64 = create_and_add_new_wrappedblob_into_memory_Internal(memoryStorage, blobToStore);

        //allocate memory and get address:
        let keyInfoSizeNeeded : Nat = key.size() + 24;
        let keyInfoMemoryAddress = MemoryRegion.allocate(memoryStorage.memory_region, keyInfoSizeNeeded);
        let keyInfoAddressNat64 : Nat64 = Nat64.fromNat(keyInfoMemoryAddress);

        // Now update the keyinfo memory values
        Region.storeNat64(memoryStorage.memory_region.region, keyInfoAddressNat64, Nat64.fromNat(keyInfoSizeNeeded));
        Region.storeNat64(memoryStorage.memory_region.region, keyInfoAddressNat64 + 8, Nat64.fromNat(key.size()));
        Region.storeNat64(memoryStorage.memory_region.region, keyInfoAddressNat64 + 16, valueStoredAddressNat64);
        Region.storeBlob(memoryStorage.memory_region.region, keyInfoAddressNat64 + 24, key);

        // Add entry in index_mappings
        var newList : List.List<Nat64> = List.nil<Nat64>();
        newList := List.push<Nat64>(keyInfoAddressNat64, newList);
        let hashedKey = Blob.hash(key);
        StableTrieMap.put(memoryStorage.index_mappings, Nat32.equal, nat32Identity, hashedKey, newList);

        return (keyInfoAddressNat64, valueStoredAddressNat64);
    };

    // Add new wrappedBlob into memory with included 'internalBlobToStore'.
    private func create_and_add_new_wrappedblob_into_memory_Internal(memoryStorage : MemoryStorage, internalBlobToStore : Blob) : Nat64 {

        // First add dummy blob into memory
        let wrappedBlobSizeNeeded : Nat = internalBlobToStore.size() + 16 + Nat64.toNat(memoryStorage.replaceBufferSize);

        //allocate memory and get address:
        let wrappedBlobMemoryAddress = MemoryRegion.allocate(memoryStorage.memory_region, wrappedBlobSizeNeeded);
        let wrappedBlobMemoryAddressNat64 : Nat64 = Nat64.fromNat(wrappedBlobMemoryAddress);

        Region.storeNat64(memoryStorage.memory_region.region, wrappedBlobMemoryAddressNat64, Nat64.fromNat(wrappedBlobSizeNeeded));
        Region.storeNat64(memoryStorage.memory_region.region, wrappedBlobMemoryAddressNat64 + 8, Nat64.fromNat(internalBlobToStore.size()));
        Region.storeBlob(memoryStorage.memory_region.region, wrappedBlobMemoryAddressNat64 + 16, internalBlobToStore);

        return wrappedBlobMemoryAddressNat64;
    };

    private func get_wrapped_blob_totalsize(memoryStorage : MemoryStorage, address : Nat64) : Nat64 {
        Region.loadNat64(memoryStorage.memory_region.region, address);
    };

};
