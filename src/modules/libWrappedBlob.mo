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
import libKeyInfo "libKeyInfo";
import { MemoryRegion } "mo:memory-region";
import libIndexMapping "libIndexMapping";

module {

    private type WrappedBlob = HashTableTypes.WrappedBlob;
    private type MemoryStorage = HashTableTypes.MemoryStorage;
    private type KeyInfo = HashTableTypes.KeyInfo;
    private func nat32Identity(n : Nat32) : Nat32 { return n };

    // Returns the wrapped-blob by address - without checking before if the item exist.
    // So we must be sure that the item on that address exist.
    public func get_wrappedBlob_from_memory(memoryStorage : MemoryStorage, address : Nat64) : WrappedBlob {
        let totalSize = Region.loadNat64(memoryStorage.memory_region.region, address);
        let blobResult : Blob = MemoryRegion.loadBlob(memoryStorage.memory_region, Nat64.toNat(address), Nat64.toNat(totalSize));
        return convert_wrappedblob_as_blob_to_wrappedBlob(blobResult);
    };

    // Add or update value by key
    public func add_or_update(key : Blob, memoryStorage : MemoryStorage, blobToStoreOrUpdate : Blob) : Nat64 {

        var hashedKey = Blob.hash(key);
        let getKeyInfoResult : (?KeyInfo, Nat64) = libKeyInfo.get_keyinfo(key, memoryStorage);
        let keyInfoOrNull = getKeyInfoResult.0;
        let keyInfoAddress : Nat64 = getKeyInfoResult.1;

        switch (keyInfoOrNull) {
            case (?keyInfo) {
                //key with value is already existing:

                let alreadyStoredWrappedBlobAddress : Nat64 = keyInfo.wrappedBlobAddress;
                let totalSizeFromAlreadyStoredBlob : Nat64 = get_wrapped_blob_totalsize(memoryStorage, alreadyStoredWrappedBlobAddress);
                let blobToStoreOrUpdateSize : Nat = blobToStoreOrUpdate.size();
                var updatePossible : Bool = false;


                if (totalSizeFromAlreadyStoredBlob > 16) {

                    let freeSizeAvailable : Nat = Nat64.toNat(totalSizeFromAlreadyStoredBlob) - 16;                           
                    if (blobToStoreOrUpdateSize <= freeSizeAvailable) {
                        updatePossible := true;
                    };
                };

                if (updatePossible == false) {

                    //Delete the old item:
                    ignore MemoryRegion.removeBlob(
                        memoryStorage.memory_region,
                        Nat64.toNat(keyInfo.wrappedBlobAddress),
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
            case (_) {
                //The key was not used before
                let addresses = add_new_item_internal_and_update_key_mappings(key, memoryStorage, blobToStoreOrUpdate);

                return addresses.1;
            };
        };

        return 0;

    };

    // Delete entry by key
    public func delete(key : Blob, memoryStorage : MemoryStorage) : Result.Result<Blob, Text> {

        let keyResult = libKeyInfo.get_keyinfo(key, memoryStorage);
        let keyInfoAddress = keyResult.1;

        switch (keyResult.0) {
            case (?keyInfo) {

                let wrappedBlobAddress : Nat64 = keyInfo.wrappedBlobAddress;

                libKeyInfo.delete_keyinfo(memoryStorage, keyInfoAddress);

                let wrappedBlobSize = get_wrapped_blob_totalsize(memoryStorage, wrappedBlobAddress);

                let deletedWrappedBlobAsBlob : Blob = MemoryRegion.removeBlob(
                    memoryStorage.memory_region,
                    Nat64.toNat(wrappedBlobAddress),
                    Nat64.toNat(wrappedBlobSize),
                );

                let deletedInternalBlob = get_internal_blob_from_blob(deletedWrappedBlobAsBlob);

                // Delete value from index-mappings-list
                libIndexMapping.remove_value(key, memoryStorage, keyInfoAddress);

                return #ok(deletedInternalBlob);

            };
            case (_) {
                return #err("Key not found.");
            };
        };
    };

    // Helper functions:

    private func add_new_item_internal_and_update_key_mappings(
        key : Blob,
        memoryStorage : MemoryStorage,
        blobToStore : Blob,
    ) : (Nat64 /* keyinfo-address*/, Nat64 /* stored wrapBlob address*/) {

        // store the blob into memory
        let valueStoredAddressNat64 : Nat64 = create_and_add_new_wrappedblob_into_memory_Internal(memoryStorage, blobToStore);

        // Create and store the related KeyInfo
        let keySize : Nat64 = Nat64.fromNat(key.size());
        let newKeyInfo : KeyInfo = {
            totalSize : Nat64 = keySize + 24;
            sizeOfKeyBlob : Nat64 = keySize;
            wrappedBlobAddress : Nat64 = valueStoredAddressNat64;
            keyAsBlob : Blob = key;
        };
        let newKeyInfoAsBlob : Blob = libKeyInfo.convert_keyinfo_to_blob(newKeyInfo);

        // Store the KeyInfo into memory
        let keyInfoAddressNat64 : Nat64 = libKeyInfo.add_new_keyinfo_directly_into_memory(memoryStorage, newKeyInfoAsBlob);

        // Add entry in index_mappings
        var newList : List.List<Nat64> = List.nil<Nat64>();
        newList := List.push<Nat64>(keyInfoAddressNat64, newList);
        let hashedKey = Blob.hash(key);
        StableTrieMap.put(memoryStorage.index_mappings, Nat32.equal, nat32Identity, hashedKey, newList);

        return (keyInfoAddressNat64, valueStoredAddressNat64);
    };

    private func create_and_add_new_wrappedblob_into_memory_Internal(memoryStorage : MemoryStorage, internalBlobToStore : Blob) : Nat64 {

        let storeItem : WrappedBlob = create_Wrapped_blob_from_internalblob(internalBlobToStore);
        let blob_fromWrappedBlob : Blob = convert_wrappedblob_to_blob(storeItem, true);
        return put_wrappedblob_as_blob_directly_into_memory(memoryStorage, blob_fromWrappedBlob);
    };

    private func create_Wrapped_blob_from_internalblob(blob : Blob) : WrappedBlob {

        let internalBlobSize = Nat64.fromNat(blob.size());
        let wrappedBlob : WrappedBlob = {
            totalSize : Nat64 = internalBlobSize + 16;  //This will be overwritten (== recalculated) during conversion to blob 
            internalBlobSize : Nat64 = internalBlobSize;
            internalBlob : Blob = blob;
        };
        return wrappedBlob;
    };

    // store the wrapped-blob as blob into memory
    private func put_wrappedblob_as_blob_directly_into_memory(memoryStorage : MemoryStorage, wrappedblob_as_blob : Blob) : Nat64 {

        let valueStoredAddress = MemoryRegion.addBlob(memoryStorage.memory_region, wrappedblob_as_blob);
        let valueStoredAddressNat64 : Nat64 = Nat64.fromNat(valueStoredAddress);
        return valueStoredAddressNat64;
    };

    private func get_wrapped_blob_totalsize(memoryStorage : MemoryStorage, address : Nat64) : Nat64 {
        let totalSize = Region.loadNat64(memoryStorage.memory_region.region, address);
        return totalSize;
    };

    private func get_internal_blob_from_blob(item : Blob) : Blob {
        let blobArray = Blob.toArray(item);
        let internalBlobSize : Nat64 = Binary.LittleEndian.toNat64(Iter.toArray(Itertools.fromArraySlice(blobArray, 8, 16)));
        let internalBlob : Blob = Blob.fromArray(Iter.toArray(Itertools.fromArraySlice(blobArray, 16, 16 + Nat64.toNat(internalBlobSize))));
        return internalBlob;
    };

    private func convert_wrappedblob_as_blob_to_wrappedBlob(item : Blob) : WrappedBlob {

        let blobArray = Blob.toArray(item);
        let totalBytes : Nat64 = Binary.LittleEndian.toNat64(Iter.toArray(Itertools.fromArraySlice(blobArray, 0, 8)));
        let internalBlobSize : Nat64 = Binary.LittleEndian.toNat64(Iter.toArray(Itertools.fromArraySlice(blobArray, 8, 16)));
        let internalBlob : Blob = Blob.fromArray(Iter.toArray(Itertools.fromArraySlice(blobArray, 16, 16 + Nat64.toNat(internalBlobSize))));

        let result : WrappedBlob = {
            totalSize = totalBytes;

            //Size of the value-blob
            internalBlobSize : Nat64 = internalBlobSize;

            //The blob-content to store
            internalBlob : Blob = internalBlob;
        };
        return result;

    };

    private func convert_wrappedblob_to_blob(item : WrappedBlob, addReplaceBuffer:Bool) : Blob {

        let blobSizeBytes : Nat64 = Nat64.fromNat(item.internalBlob.size());
        var totalBytes : Nat64 = blobSizeBytes + 16; // 16 bytes => 2 * Nat64 = 2 * 8 bytes = 16 bytes
        if (addReplaceBuffer == true){
            totalBytes:=totalBytes + 8;
        };

        let blob_totalSize : [Nat8] = Binary.LittleEndian.fromNat64(totalBytes);
        let blob_internalBlobSize : [Nat8] = Binary.LittleEndian.fromNat64(item.internalBlobSize);

        var iter = Iter.fromArray(blob_totalSize);
        iter := Itertools.chain(iter, Iter.fromArray(blob_internalBlobSize));
        iter := Itertools.chain(iter, Iter.fromArray(Blob.toArray(item.internalBlob)));
        if (addReplaceBuffer == true){
            // Add 8 bytes (Nat64 as blob)
            iter := Itertools.chain(iter, Iter.fromArray(blob_internalBlobSize));
        };

        let result : Blob = Blob.fromArray(Iter.toArray(iter));
        return result;

    };

};
