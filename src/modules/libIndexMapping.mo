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

module {

    private type MemoryStorage = HashTableTypes.MemoryStorage;
    private func nat32Identity(n : Nat32) : Nat32 { return n };

    // Rmove key from index-mapping list
    public func remove_value(key : Blob, memoryStorage : MemoryStorage, valueToRemove : Nat64) {

        var keyHash : Nat32 = Blob.hash(key);
        let currentIndizesOrNull = StableTrieMap.get(memoryStorage.index_mappings, Nat32.equal, nat32Identity, keyHash);
        switch (currentIndizesOrNull) {
            case (?listOfIndizes) {
                let newList = List.filter<Nat64>(listOfIndizes, func n { n != valueToRemove });
                if (List.size(newList) == 0) {
                    StableTrieMap.delete(memoryStorage.index_mappings, Nat32.equal, nat32Identity, keyHash);
                } else {
                    StableTrieMap.put(memoryStorage.index_mappings, Nat32.equal, nat32Identity, keyHash, newList);
                };
            };
            case (_) {
                StableTrieMap.delete(memoryStorage.index_mappings, Nat32.equal, nat32Identity, keyHash);
            };
        };
    };

    // Get keyinfo-memory adresses for a provided key
    public func get_values(key : Blob, memoryStorage : MemoryStorage) : List.List<Nat64> {

        var keyHash : Nat32 = Blob.hash(key);
        let currentIndizesOrNull = StableTrieMap.get(memoryStorage.index_mappings, Nat32.equal, nat32Identity, keyHash);
        switch (currentIndizesOrNull) {
            case (?indizesList) {
                return indizesList;
            };
            case (_) {
                return List.nil<Nat64>();
            };
        };

    };

};
