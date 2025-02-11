import "@stdlib/deploy";

// Allows the contract to receive a custom object of type "Save" specifying the number to save in the contract.
message Save {
    amount: Int as uint32;
}

// This is an example of a simple storage contract. It has a function that increments the saved number by one when the function is called.
contract BettingGame with Deployable {

    // Declare variables
    // Variables structure: name: type 

    id: Int as uint32; // This is an ID for contract deployment
    savedNumber: Int as uint32;  
    counter: Int as uint32;  
    
    // init is similar to a contructor in Solidity
    init(id: Int) {

        // Init the id assed from the contructor
        self.id = id;

        // Initialize the variables to zero when the contract is deployed
        self.savedNumber = 0;
        self.counter = 0;
    }

    // TON contracts can recevie messages
    // This function makes an action when a specific message is recevied
    // In this case, when the contract recevies the message "add 1" will increment the counter variable by 1
    receive("add 1"){
        self.counter = self.counter + 1; 
    }

    receive("add 3"){
        self.counter = self.counter + 3; 
    }


    // This allows the contract to recevie objects, in this case of type "Save"
    // Save a value in the contract
    receive(msg: Save){
        self.savedNumber = msg.amount;
    }

    // Getter function to read the variable
    get fun Number(): Int { // Int is the type of value returned
        return self.savedNumber;
    }

    // Getter function to read the counter variable
    get fun Counter(): Int { // Int is the type of value returned
        return self.counter;
    }

    // Getter function for the ID
    get fun Id(): Int {
        return self.id;
    }
}

