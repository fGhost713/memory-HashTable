import HashTableTypes "../types/hashTableTypes";
import LibKeyInfo "libKeyInfo";
import LibWrappedBlob "libWrappedBlob";
import CommonHashTable "commonHashTable";
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
            let keyInfo : (?KeyInfo, Nat64 /*address of keyinfo*/) = LibKeyInfo.get_keyinfo(key, memoryStorage);

            let keyInfoOrNull = keyInfo.0;
            switch (keyInfoOrNull) {
                case (?keyinfo) {
                    let wrappedBlob : WrappedBlob = LibWrappedBlob.get_wrappedBlob_from_memory(
                        memoryStorage,
                        keyinfo.wrappedBlobAddress,
                    );

                    return Option.make(wrappedBlob.internalBlob);
                };
                case (_) {
                    return null;
                };
            };
        };

        // Delete value by key
        public func delete(key : Blob) : ?Blob {
            let result = LibWrappedBlob.delete(key, memoryStorage);
            switch (result){
                case (#ok(blob)){
                    return Option.make(blob);
                };
                case (_){
                    return null;
                }
            };
        };
    };

};
