# memory-hashtable

## Notice

This module is built on top of the MemoryRegion module from NatLabs. (https://github.com/NatLabs/memory-region)

Thanks to Natlabs for their incredible work.

## Description
The module memory-hashtable is designed to store, update, delete, and retrieve a blob-value that is associated with a specific blob-key. This creates a mapping from the key to the value, where both the key and value are of type blob. The storing is taking place into memory, where more than 32 GB can be used.

Key:

The method 'to_candid' should never be used to generate the blob-key. The blob key must be deterministic, meaning that it should always be the same for the same key. However, this is not guaranteed for the 'to_candid' method.
(see https://forum.dfinity.org/t/candid-to-candid-motoko-assumptions)


Value:

Generating the corresponding blob (from value) with the 'to_candid' method is not problematic as no equality-check is required
for the blob-value.

## Installation

This module is provided through the package-manager mops. If you want install this module into your motoko project then you need to execute these steps in the console.

1) Navigate into your motoko project folder

2) If mops is not already installed, then install mops:

        sudo npm i -g ic-mops

3) Initialize mops:

        mops init

3) Install this module:

	    mops add memory-hashtable


## Example usage


    import Blob "mo:base/Blob";
    import Nat64 "mo:base/Nat64";
    import lib "mo:memory-hashtable";

    actor {

        // (1) Initialize the memory-storage. Here parameter value 8 is used. 
        // This means that we will use 8 bytes as replace-buffer.
        //     So if we later want to update a blob for a key (in memory), 
        //     and the new blob-size is not greater than the
        //     size of the initial-blob + 8 bytes (replacebuffer) then the existing 
        //     memory-location will be used for updating the blob.
        //     Else we will need to allocate new memory and store the blob into new location.

        stable var mem = lib.get_new_memory_storage(8);
        
        // (2) Instanciate the hashTable with 'memoryStorage' as parameter
        
        let hashTable = lib.MemoryHashTable(mem);
        

        public shared func examples():async (){

            let key1:Blob = lib.Blobify.Text.to_blob("key1");
            let key2:Blob = lib.Blobify.Text.to_blob("key2");

            let blob1 : Blob = lib.Blobify.Text.to_blob("hello world");
            let blob2 : Blob = lib.Blobify.Text.to_blob("example value");
            
            // (3) Example of adding new entries;
            
            ignore hashTable.put(key1, blob1);
            ignore hashTable.put(key2, blob2);


            // (4) Example of overwriting existing value for key1
            
            let storedMemoryAddress:Nat64 = hashTable.put(key1, blob2);


            // (5) Example of getting the blob-value for the key 'key1'.
            //     -> The value will be null if key was not found.
            
            let blobValue:?Blob = hashTable.get(key1);


            // (6) Example of deleting existing key (and the related value)
            
            hashTable.delete(key1);
        };
    };


## Benchmarks

    Running bench/add_items.bench.mo...



    Adding new items

    Add new items benchmark


    Instructions

    |                 |      1 |      10 |       100 |       1000 |       10000 |
    | :-------------- | -----: | ------: | --------: | ---------: | ----------: |
    | memoryHashTable | 18_692 | 158_980 | 1_931_819 | 22_798_640 | 267_334_891 |


    Heap

    |                 |   1 |  10 |   100 |   1000 |   10000 |
    | :-------------- | --: | --: | ----: | -----: | ------: |
    | memoryHashTable | 332 | 988 | 8_020 | 78_472 | 796_224 |


    ——————————————————————————————————————————————————

    Running bench/delete_items.bench.mo...



    Delete existing items

    Delete existing items benchmark


    Instructions

    |                 |      1 |      10 |       100 |       1000 |       10000 |
    | :-------------- | -----: | ------: | --------: | ---------: | ----------: |
    | memoryHashTable | 29_811 | 281_762 | 2_935_332 | 29_415_589 | 284_147_554 |


    Heap

    |                 |   1 |   10 |    100 |    1000 |    10000 |
    | :-------------- | --: | ---: | -----: | ------: | -------: |
    | memoryHashTable | 192 | -668 | -7_496 | -80_668 | -793_048 |


    ——————————————————————————————————————————————————

    Running bench/get_items.bench.mo...



    Get items

    Get existing items benchmark


    Instructions

    |                 |      1 |     10 |     100 |       1000 |       10000 |
    | :-------------- | -----: | -----: | ------: | ---------: | ----------: |
    | memoryHashTable | 10_433 | 89_267 | 959_331 | 10_205_446 | 109_313_888 |


    Heap

    |                 |   1 |  10 | 100 | 1000 | 10000 |
    | :-------------- | --: | --: | --: | ---: | ----: |
    | memoryHashTable | 228 | 228 | 228 |  228 |   228 |


    ——————————————————————————————————————————————————

    Running bench/update_items.bench.mo...



    Updating existing items

    Updating existing items benchmark


    Instructions

    |                 |      1 |     10 |       100 |       1000 |       10000 |
    | :-------------- | -----: | -----: | --------: | ---------: | ----------: |
    | memoryHashTable | 11_953 | 95_558 | 1_017_510 | 10_806_649 | 115_856_995 |


    Heap

    |                 |   1 |  10 | 100 | 1000 | 10000 |
    | :-------------- | --: | --: | --: | ---: | ----: |
    | memoryHashTable | 228 | 228 | 228 |  228 |   228 |


    ——————————————————————————————————————————————————

    Running bench/update_too_big_items.bench.mo...



    Updating with fallback to put

    Updating with fallback to put benchmark


    Instructions

    |                 |      1 |      10 |       100 |       1000 |       10000 |
    | :-------------- | -----: | ------: | --------: | ---------: | ----------: |
    | memoryHashTable | 27_138 | 241_482 | 2_809_671 | 31_574_397 | 347_743_654 |


    Heap

    |                 |   1 |  10 |   100 |   1000 |   10000 |
    | :-------------- | --: | --: | ----: | -----: | ------: |
    | memoryHashTable | 260 | 372 | 3_084 | 29_536 | 294_436 |







