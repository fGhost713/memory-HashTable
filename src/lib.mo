import HashTableTypes "types/hashTableTypes";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import BlobifyModule "helpers/blobify";
import { MemoryRegion } "mo:memory-region";
import StableTrieMap "helpers/stableTrieMap";
import MemoryHashTableModule "/modules/memoryHashTable";

module {

	public type MemoryStorage = HashTableTypes.MemoryStorage;
	private type KeyInfo = HashTableTypes.KeyInfo;
	private type WrappedBlob = HashTableTypes.WrappedBlob;
	public let Blobify = BlobifyModule;
	public let MemoryHashTable = MemoryHashTableModule.MemoryHashTable;

	public func get_new_memory_storage(replaceBufferSizeInBytes:Nat) : MemoryStorage {

        var replaceBufferArray:[Nat8] = [];

        if (replaceBufferSizeInBytes > 0){
            replaceBufferArray := Array.tabulate<Nat8>(replaceBufferSizeInBytes, func i = 255);
            assert (replaceBufferArray.size() == replaceBufferSizeInBytes);
        };

        let newItem : MemoryStorage = {
            memory_region = MemoryRegion.new();
            index_mappings = StableTrieMap.new();
            replaceBufferSize:Nat64 = Nat64.fromNat(replaceBufferSizeInBytes);
            replaceBufferAsBlob:[Nat8] = replaceBufferArray;
        };
        return newItem;
    };
};
