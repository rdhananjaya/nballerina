import ballerina/io;

public function main() {
    foo(0.0);
}

function foo(float f) {
    if f == 0.0 {
        if f != 0.0 {
            io:println("unreached"); // @error
        }

    }
}