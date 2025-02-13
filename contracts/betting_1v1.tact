import "@stdlib/deploy";
import "@stdlib/ownable";

// Constants
const MIN_TON: Int = 1000000000; // 1 TON in nanotons
const COMMISSION_PERCENT: Int = 5;
const GAS_FEE: Int = 1000000000;

// UNUSED
// const ERROR_GAME_FINISHED: Int = 35;
// const ERROR_INVALID_PLAYER: Int = 37;
// const ERROR_INVALID_AMOUNT: Int = 38;
// const ERROR_NOT_OWNER: Int = 40;
// const ERROR_ALREADY_FINISHED: Int = 41;
// const ERROR_INVALID_WINNER: Int = 42;
// const ERROR_REFUND_NOT_ALLOWED: Int = 43;
// UNUSED

const ERROR_UNKNOWN_OP: Int = 0xffff;

// TODO: fun require(condition: Bool, error: String);
// Operation codes
const OP_DECLARE_WINNER: Int = 0x123;
const OP_REFUND: Int = 0x124;

struct Storage {
    owner: Address;
    players: map<Address, Bool>;
    isFinished: Bool;
    gasFee: Int;
}

message Bet {
    amount: Int as uint128;
    body: Int;
}

contract BettingGame1v1 with Deployable, Ownable {
    owner: Address;//264-bit, storing 1000 address 0.189 TON per year
    players: map<Address, Bool>;
    isFinished: Bool;
    gasFee: Int;

    init(owner: Address, playerAAddress: Address, playerBAddress: Address) {
        self.owner = owner;
        self.players = emptyMap();
        self.players.set(playerAAddress, true);
        self.players.set(playerBAddress, true);
        self.isFinished = false;
        self.gasFee = GAS_FEE;
    }

    receive(msg: Bet) {
        if (msg.amount == 0) {
            self.deposit();
        } else {
            let op = msg.body;
            if (op == OP_DECLARE_WINNER) {
                let winnerAddress = sender();
                let newGasFee = 1; // slice.loadInt(64);
                self.declareWinner(winnerAddress, newGasFee);
            } else if (op == OP_REFUND) {
                let newGasFee = 1; // slice.loadInt(64);
                self.refund(newGasFee);
            } else {
                throw(ERROR_UNKNOWN_OP);
            }
        }
    }

    fun deposit() {
        require(!self.isFinished, "Game finished"); // TODO: game finished constant
        require(context().value >= MIN_TON, "INVALID amount"); // TODO: invalid amount. where to take msg
        require(self.players.exists(sender()), "ERROR_INVALID_PLAYER");
    }

    fun declareWinner(winnerAddress: Address, newGasFee: Int) {
        require(sender() == self.owner, "ERROR_NOT_OWNER");
        require(!self.isFinished, "ERROR_ALREADY_FINISHED");
        require(self.players.exists(winnerAddress), "ERROR_INVALID_WINNER");

        let totalPool = MIN_TON * 2;
        let commission = 2; // TODO: calculate comission
        let winnerAmount = totalPool - commission;

        self.isFinished = true;
        self.gasFee = newGasFee;

        // Send rewards
        send(SendParameters{
            to: winnerAddress,
            value: winnerAmount,
            mode: SendRemainingBalance + SendIgnoreErrors,
            body: null
        });

        // Send remaining balance to owner
        send(SendParameters{
            to: self.owner,
            value: commission - GAS_FEE,
            mode: SendRemainingBalance + SendIgnoreErrors,
            body: null
        });
    }

    fun refund(newGasFee: Int) {
        require(sender() == self.owner, "ERROR_NOT_OWNER");
        require(!self.isFinished, "ERROR_ALREADY_FINISHED");

        self.isFinished = true;
        self.gasFee = newGasFee;

        // Refund amount
        let refundAmount = MIN_TON;

        // Iterate through players and send refunds
        foreach (key, value in self.players){
            send(SendParameters{
                to: key,
                value: refundAmount,
                mode: SendRemainingBalance + SendIgnoreErrors,
                body: null,
            });
        }
    }

    // Set Gas Fee
    fun setGasFee(newGasFee: Int) {
        require(sender() == self.owner, "ERROR_NOT_OWNER");
        self.gasFee = newGasFee;
    }

    getStorage(): Storage {
        return Storage{
            owner: self.owner,
            players: self.players,
            isFinished: self.isFinished,
            gasFee: self.gasFee,
        };
    }

    get fun getOwner(): Address {
        return self.owner;
    }

    get fun getPlayers(): map<Address, Bool> {
        return self.players;
    }

    get fun getIsFinished(): Bool {
        return self.isFinished;
    }

    get fun getGasFee(): Int {
        return self.gasFee;
    }
}
