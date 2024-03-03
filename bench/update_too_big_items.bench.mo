import Bench "mo:bench";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import lib "../src/lib";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

module {
    public func init() : Bench.Bench {

        let bench = Bench.Bench();

        bench.name("Updating with fallback to put");
        bench.description("Updating with fallback to put benchmark");

        bench.rows(["memoryHashTable"]);
        bench.cols(["1","10", "100", "1000","10000"]);

        type OwnType = {
            myNumber : Nat;
            myText : Text;
        };
        

        let ownType1 : OwnType = {
            myNumber : Nat = 2345;
            myText : Text = "Hello World";
        };

        let wonTypeNotFit:OwnType = {
            myNumber : Nat = 2345;
            myText : Text = "Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World";

        };

        let ownType1Blob : Blob = to_candid (ownType1);
        let wonTypeNotFitBlob : Blob = to_candid (wonTypeNotFit);

        let memoryItem = lib.get_new_memory_storage(0);
        let mem = lib.MemoryHashTable(memoryItem);

         for (i in Iter.range(1, 10000)) {
                        let key1 : Blob = lib.Blobify.Text.to_blob("key"#debug_show(i));
                        ignore mem.put(key1, ownType1Blob);
         };


        bench.runner(
            func(row, col) {
                let ?n = Nat.fromText(col);

                // Vector
                if (row == "memoryHashTable") {
                    for (i in Iter.range(1, n)) {
                        let key1 : Blob = lib.Blobify.Text.to_blob("key"#debug_show(i));
                        ignore mem.put(key1, wonTypeNotFitBlob);
                    };
                };
            }
        );

        bench;
    };
};
