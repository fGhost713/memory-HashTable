import HashTableTypes "../types/hashTableTypes";
import LibKeyInfo "libKeyInfo";
import LibWrappedBlob "libWrappedBlob";
import Option "mo:base/Option";
import Result "mo:base/Result";
import BlobifyModule "mo:memory-buffer/Blobify";
import { MemoryRegion } "mo:memory-region";
import StableTrieMap "mo:StableTrieMap";

module {

    public type MemoryStorage = HashTableTypes.MemoryStorage;
    private type KeyInfo = HashTableTypes.KeyInfo;
    private type WrappedBlob = HashTableTypes.WrappedBlob;

    public class MemoryHashTable(memoryStorageToUse : MemoryStorage) {
        let memoryStorage : MemoryStorage = memoryStorageToUse;

        // Add or update value by key
        public func put(key : Blob, value : Blob) : Nat64 {
            return LibWrappedBlob.add_or_update(key, memoryStorage, value);
        };

        // Get value (as blob) by key
        public func get(key : Blob) : ?Blob {

            let memoryAddressesOrNull = LibKeyInfo.get_memory_addresses(key, memoryStorage);
            
            switch (memoryAddressesOrNull) {
                case (?memoryAddresses) {                 
                    let wrappedBlobAddress = memoryAddresses.1;
                    let internalBlob:Blob = LibWrappedBlob.get_internal_blob_from_memory( memoryStorage,
                        wrappedBlobAddress);
                    return Option.make(internalBlob);
                };
                case (_) {
                    return null;
                };
            };
        };

        // Delete value by key
        public func delete(key : Blob) {
            LibWrappedBlob.delete(key, memoryStorage);         
        };

    };

};
