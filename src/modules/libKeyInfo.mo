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

    // Convert keyinfo as blob into keyinfo type
    public func convert_keyinfo_blob_to_keyinfo(blob : Blob) : KeyInfo {

        let blobArray = Blob.toArray(blob);

        let totalBytes : Nat64 = Binary.LittleEndian.toNat64(Iter.toArray(Itertools.fromArraySlice(blobArray, 0, 8)));
        let internalBlobSize : Nat64 = Binary.LittleEndian.toNat64(Iter.toArray(Itertools.fromArraySlice(blobArray, 8, 16)));
        let address : Nat64 = Binary.LittleEndian.toNat64(Iter.toArray(Itertools.fromArraySlice(blobArray, 16, 24)));
        let internalBlob : Blob = Blob.fromArray(Iter.toArray(Itertools.fromArraySlice(blobArray, 24, 24 + Nat64.toNat(internalBlobSize))));

        let result : KeyInfo = {
            totalSize : Nat64 = totalBytes;
            sizeOfKeyBlob : Nat64 = internalBlobSize;
            wrappedBlobAddress : Nat64 = address;
            keyAsBlob : Blob = internalBlob;
        };

        return result;

    };

    // Convert keyinfo-type to blob
    public func convert_keyinfo_to_blob(keyInfo : KeyInfo) : Blob {

        let blobSizeBytes : Nat64 = Nat64.fromNat(keyInfo.keyAsBlob.size());
        let totalBytes : Nat64 = blobSizeBytes + 24;

        let blob_totalSize : [Nat8] = Binary.LittleEndian.fromNat64(totalBytes);
        let blob_sizeOfKeyBlob : [Nat8] = Binary.LittleEndian.fromNat64(blobSizeBytes);
        let blob_address : [Nat8] = Binary.LittleEndian.fromNat64(keyInfo.wrappedBlobAddress);

        var iter = Iter.fromArray(blob_totalSize);
        iter := Itertools.chain(iter, Iter.fromArray(blob_sizeOfKeyBlob));
        iter := Itertools.chain(iter, Iter.fromArray(blob_address));
        iter := Itertools.chain(iter, Iter.fromArray(Blob.toArray(keyInfo.keyAsBlob)));
        
        let result : Blob = Blob.fromArray(Iter.toArray(iter));
        return result;

    };

    // Get keyinfo by key
    public func get_keyinfo(key : Blob, memoryStorage : MemoryStorage) : (?KeyInfo, Nat64 /*address of keyinfo*/) {

        var keySize = Nat64.fromNat(key.size());
        var keyHash : Nat32 = Blob.hash(key);

        let valuesList = libIndexMapping.get_values(key, memoryStorage);
        let listSize : Nat = List.size(valuesList);
        if (listSize == 0) {
            return (null, 0);
        };

        for (index in Iter.range(0, listSize -1)) {
            let indexOrNull = List.get(valuesList, index);
            switch (indexOrNull) {
                case (?foundAddress) {
                    let keyInfoOrNull : ?KeyInfo = get_keyinfo_internal(memoryStorage, foundAddress);
                    switch (keyInfoOrNull) {
                        case (?keyInfo) {
                            if (keyInfo.sizeOfKeyBlob == keySize) {
                                if (Blob.equal(keyInfo.keyAsBlob, key) == true) {
                                    return (keyInfoOrNull, foundAddress);
                                };
                            };
                        };
                        case (_) {
                            //do nothing
                        };
                    };
                };
                case (_) {
                    // do nothing
                };

            };
        };

        return (null, 0);

    };

    // Store the new KeyInfo into memory
    public func add_new_keyinfo_directly_into_memory(memoryStorage : MemoryStorage, keyinfo_as_blob : Blob) : Nat64 {
        let keyInfoAddress = MemoryRegion.addBlob(memoryStorage.memory_region, keyinfo_as_blob);
        let keyInfoAddressNat64 : Nat64 = Nat64.fromNat(keyInfoAddress);
        return keyInfoAddressNat64;
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
        ignore MemoryRegion.removeBlob(
            memoryStorage.memory_region,
            Nat64.toNat(keyInfoAddress),
            Nat64.toNat(keyInfoSize),
        );

    };

    private func get_keyinfo_internal(memoryStorage : MemoryStorage, address : Nat64) : ?KeyInfo {
        let sizeNeeded = Region.loadNat64(memoryStorage.memory_region.region, address);
        let keyInfoBlob : Blob = MemoryRegion.loadBlob(memoryStorage.memory_region, Nat64.toNat(address), Nat64.toNat(sizeNeeded));
        let resultOrNull : ?KeyInfo = Option.make(convert_keyinfo_blob_to_keyinfo(keyInfoBlob));
        return resultOrNull;
    };

};
