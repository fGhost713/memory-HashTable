import HashTableTypes "types/hashTableTypes";
import LibKeyInfo "modules/libKeyInfo";
import LibWrappedBlob "modules/libWrappedBlob";
import CommonHashTable "modules/commonHashTable";
import Option "mo:base/Option";
import BlobifyModule "mo:memory-buffer/Blobify";
import { MemoryRegion } "mo:memory-region";
import StableTrieMap "mo:StableTrieMap";
import MemoryHashTableModule "/modules/memoryHashTable";

module {
	
	public type MemoryStorage = HashTableTypes.MemoryStorage;
	private type KeyInfo = HashTableTypes.KeyInfo;
	private type WrappedBlob = HashTableTypes.WrappedBlob;
	public let Blobify = BlobifyModule;
	public let MemoryHashTable = MemoryHashTableModule.MemoryHashTable;

	public func get_new_memory_storage() : MemoryStorage {
        let newItem : MemoryStorage = {
            memory_region = MemoryRegion.new();
            index_mappings = StableTrieMap.new();
        };
        return newItem;
    };
};