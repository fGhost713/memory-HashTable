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

### Description

    the benchmarks uses 'ownType1Blob' as the blob-value for the storing/updating/deleting/retrieving operations:
        
        type OwnType = {
            myNumber : Nat;
            myText : Text;
        };

        let ownType1 : OwnType = {
            myNumber : Nat = 2345;
            myText : Text = "Hello World";
        };

        let ownType1Blob : Blob = to_candid (ownType1);



### Benchmark results

    Running bench/add_items.bench.mo...



    Adding new items

    Add new items benchmark


    Instructions

    |                 |      1 |     10 |       100 |       1000 |       10000 |
    | :-------------- | -----: | -----: | --------: | ---------: | ----------: |
    | memoryHashTable | 10_613 | 82_130 | 1_095_076 | 13_631_875 | 164_314_566 |


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
    | memoryHashTable | 26_584 | 257_644 | 2_614_367 | 25_494_490 | 234_850_961 |


    Heap

    |                 |   1 |   10 |    100 |    1000 |    10000 |
    | :-------------- | --: | ---: | -----: | ------: | -------: |
    | memoryHashTable | 176 | -720 | -7_428 | -80_684 | -793_048 |


    ——————————————————————————————————————————————————

    Running bench/get_items.bench.mo...



    Get items

    Get existing items benchmark


    Instructions

    |                 |     1 |     10 |     100 |      1000 |      10000 |
    | :-------------- | ----: | -----: | ------: | --------: | ---------: |
    | memoryHashTable | 8_381 | 69_071 | 695_231 | 6_834_881 | 65_523_303 |


    Heap

    |                 |   1 |  10 | 100 | 1000 | 10000 |
    | :-------------- | --: | --: | --: | ---: | ----: |
    | memoryHashTable | 228 | 228 | 228 |  228 |   228 |


    ——————————————————————————————————————————————————

    Running bench/update_items.bench.mo...

    |                 |     1 |     10 |     100 |      1000 |      10000 |
    | :-------------- | ----: | -----: | ------: | --------: | ---------: |
    | memoryHashTable | 9_825 | 74_450 | 744_066 | 7_342_090 | 71_126_382 |


    Heap

    |                 |   1 |  10 | 100 | 1000 | 10000 |
    | :-------------- | --: | --: | --: | ---: | ----: |
    | memoryHashTable | 228 | 228 | 228 |  228 |   228 |


    ——————————————————————————————————————————————————

    Running bench/update_too_big_items.bench.mo...

    |                 |      1 |      10 |       100 |       1000 |       10000 |
    | :-------------- | -----: | ------: | --------: | ---------: | ----------: |
    | memoryHashTable | 14_227 | 123_261 | 1_563_097 | 18_380_590 | 205_731_563 |


    Heap

    |                 |   1 |  10 |   100 |   1000 |   10000 |
    | :-------------- | --: | --: | ----: | -----: | ------: |
    | memoryHashTable | 260 | 372 | 3_084 | 29_536 | 294_436 |







