import "@stdlib/deploy";
import "@stdlib/ownable";

// Constants
const COMMISSION_PERCENT: Int = 5;
const JETTON_TRANSFER_OP: Int = 0x7362d09c; // Jetton transfer opcode
const OP_DECLARE_WINNER: Int = 0x123;
const OP_REFUND: Int = 0x124;
const ERROR_UNKNOWN_OP: Int = 0xffff;

// Array Struct for Players
struct PlayersArray {
    m: map<Int as uint16, Address>; // Map to store players by index
    length: Int = 0;                // Length of the array
}

// Compile-time constant upper bound for the players array
const MaxPlayers: Int = 3; // Maximum of 3 players (1v1v1)

// Extension function to add a player to the array
extends mutates fun append(self: PlayersArray, player: Address) {
    require(self.length < MaxPlayers, "Maximum players reached!");
    self.m.set(self.length, player);
    self.length += 1;
}

// Extension function for getting the value at the given index
extends fun getIdx(self: Array, idx: Int): Int {
    require(self.length > 0, "No items in the array!");
    require(idx >= 0, "Index of the item cannot be negative!");
    require(idx < self.length, "Index is out of array bounds!");

    // Note, that we use !! operator as we know for sure that the value would be there
    return self.m.get(idx)!!;
}

// Extension function to check if a player exists in the array
extends fun contains(self: PlayersArray, player: Address): Bool {
    let i: Int = 0;
    while (i + 1 < self.length) {
        // Note, that we use !! operator as we know for sure that the value would be there
        if (self.m.get(i) == player) {
        return true;
    }
    return false;
}

contract GameManager with Deployable, Ownable, Jetton {
    // Storage
    lobbyId: Int;
    owner: Address;
    players: PlayersArray;
    maxPlayers: Int;
    betAmount: Int;
    jettonMaster: Address;
    depositedPlayers: map<Address, Bool>;
    isFinished: Bool;
    gasFee: Int;

    init(owner: Address, lobbyId: Int, players: PlayersArray, betAmount: Int, jettonMaster: Address) {
        self.owner = owner;
        self.lobbyId = lobbyId;
        self.players = PlayersArray{m: emptyMap(), length: 0};
        self.maxPlayers = players.length();
        self.betAmount = betAmount;
        self.jettonMaster = jettonMaster;
        self.depositedPlayers = emptyMap();
        self.isFinished = false;
        self.gasFee = 1000000000; // Initial gas fee

        // Add players to the array
        for (player in players) {
            self.players.append(player);
        }
    }

    receive() {
        let sender = context().sender;
        // Handle Jetton transfers
        if (sender == self.resolveJettonWallet()) {
            let slice = context().body.beginParse();
            let op = slice.loadUint(32);
            if (op == JETTON_TRANSFER_OP) {
                self.handleJettonTransfer(slice);
                return;
            }
        }
        // Handle admin operations
        self.handleAdminOperations();
    }

    fun handleJettonTransfer(slice: Slice) {
        let queryId = slice.loadUint(64);
        let amount = slice.loadCoins();
        let fromAddress = slice.loadAddress();
        
        require(self.players.contains(fromAddress), "Invalid player");
        require(amount == self.betAmount, "Incorrect bet");
        require(!self.depositedPlayers.exists(fromAddress), "Already deposited");
        
        self.depositedPlayers.set(fromAddress, true);
    }

    fun handleAdminOperations() {
        let slice = context().body.beginParse();
        let op = slice.loadUint(32);
        
        if (op == OP_DECLARE_WINNER) {
            let winnerAddress = slice.loadAddress();
            let newGasFee = slice.loadCoins();
            self.declareWinner(winnerAddress, newGasFee);
        } else if (op == OP_REFUND) {
            let newGasFee = slice.loadCoins();
            self.refund(newGasFee);
        } else {
            throw(ERROR_UNKNOWN_OP);
        }
    }

    fun declareWinner(winnerAddress: Address, newGasFee: Int) {
        require(sender() == self.owner, "Not owner");
        require(!self.isFinished, "Game finished");
        require(self.players.contains(winnerAddress), "Invalid winner");
        require(self.depositedPlayers.size() == self.maxPlayers, "Missing deposits");

        let totalPool = self.betAmount * self.maxPlayers;
        let commission = (totalPool * COMMISSION_PERCENT) / 100;
        let winnerAmount = totalPool - commission;
        let ownerAmount = commission - self.gasFee;

        self.isFinished = true;
        self.gasFee = newGasFee;

        // Send prizes
        self.jettonTransfer(winnerAddress, winnerAmount);
        self.jettonTransfer(self.owner, ownerAmount);
    }

    fun refund(newGasFee: Int) {
        require(sender() == self.owner, "Not owner");
        require(!self.isFinished, "Game finished");

        self.isFinished = true;
        self.gasFee = newGasFee;

        for (i in 0..self.players.length) {
            let player = self.players.m.get(i)!!;
            if (self.depositedPlayers.exists(player)) {
                self.jettonTransfer(player, self.betAmount);
            }
        }
    }

    fun jettonTransfer(to: Address, amount: Int) {
        let body = beginCell()
            .storeUint(0x0f8a7ea5, 32)  // transfer op
            .storeUint(0, 64)           // query_id
            .storeCoins(amount)
            .storeAddress(to)
            .storeAddress(null)         // response_address
            .storeBit(0)                // no custom_payload
            .storeCoins(0)              // forward_ton_amount
            .endCell();

        send(SendParameters{
            to: self.resolveJettonWallet(),
            value: self.gasFee,
            mode: SendRemainingBalance,
            body: body
        });
    }

    fun resolveJettonWallet(): Address {
        // Calculate jetton wallet address using jetton master and contract address
        let jettonWalletCode = self.jettonMaster.loadCode();
        let stateInit = StateInit{
            code: jettonWalletCode,
            data: beginCell()
                .storeAddress(self.address)
                .storeAddress(self.jettonMaster)
                .endCell()
        };
        return address(stateInit);
    }

    // Getter functions
    get fun getStorage(): Storage {
        return Storage{
            lobbyId: self.lobbyId,
            owner: self.owner,
            players: self.players,
            maxPlayers: self.maxPlayers,
            betAmount: self.betAmount,
            jettonMaster: self.jettonMaster,
            depositedPlayers: self.depositedPlayers,
            isFinished: self.isFinished,
            gasFee: self.gasFee
        };
    }
}