import StableTrieMap "mo:StableTrieMap";
import Nat32 "mo:base/Nat32";
import { MemoryRegion } "mo:memory-region";
import HashTableTypes "../types/hashTableTypes";
import libKeyInfo "libKeyInfo";
import libWrappedBlob "libWrappedBlob";

module {

    public type MemoryStorage = HashTableTypes.MemoryStorage;
    public type KeyInfo = HashTableTypes.KeyInfo;
    public type WrappedBlob = HashTableTypes.WrappedBlob;

    private func nat32Identity(n : Nat32) : Nat32 { return n };

    public func get_new_memory_storage() : MemoryStorage {
        let newItem : MemoryStorage = {
            memory_region = MemoryRegion.new();
            index_mappings = StableTrieMap.new();
        };
        return newItem;
    };

};
