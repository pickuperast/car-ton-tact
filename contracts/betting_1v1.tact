import "@stdlib/deploy";

// Constants
const MIN_TON: Int = 1000000000; // 1 TON in nanotons
const COMMISSION_PERCENT: Int = 5;
const GAS_FEE: Int = 1000000000;

// Error codes
const ERROR_GAME_FINISHED: Int = 35;
const ERROR_INVALID_PLAYER: Int = 37;
const ERROR_INVALID_AMOUNT: Int = 38;
const ERROR_NOT_OWNER: Int = 40;
const ERROR_ALREADY_FINISHED: Int = 41;
const ERROR_INVALID_WINNER: Int = 42;
const ERROR_REFUND_NOT_ALLOWED: Int = 43;
const ERROR_UNKNOWN_OP: Int = 0xffff;

// Operation codes
const OP_DECLARE_WINNER: Int = 0x123;
const OP_REFUND: Int = 0x124;

struct Storage {
    owner: Address;
    players: Map<Address, Bool>;
    isFinished: Bool;
    gasFee: Int;
}

message Bet {
    amount: Int as uint128;
}

contract BettingGame1v1 with Deployable {
    owner: Address;//264-bit, storing 1000 address 0.189 TON per year
    players: Map<Address, Bool>;
    isFinished: Bool;
    gasFee: Int;

    init(playerAAddress: Address, playerBAddress: Address) {
        this.owner = sender();
        this.players = new Map<Address, Bool>();
        this.players.set(playerAAddress, true);
        this.players.set(playerBAddress, true);
        this.isFinished = false;
        this.gasFee = GAS_FEE;
    }

    receive(msg: Bet) {
        if (msg.body.empty?) {
            this.deposit();
        } else {
            let slice = msg.body.asSlice();
            let op = slice.loadInt(32);

            if (op == OP_DECLARE_WINNER) {
                let winnerAddress = slice.loadAddress();
                let newGasFee = slice.loadInt(64);
                this.declareWinner(winnerAddress, newGasFee);
            } else if (op == OP_REFUND) {
                let newGasFee = slice.loadInt(64);
                this.refund(newGasFee);
            } else {
                throw(ERROR_UNKNOWN_OP);
            }
        }
    }

    deposit() {
        require(!this.isFinished, ERROR_GAME_FINISHED);
        require(msg.value >= MIN_TON, ERROR_INVALID_AMOUNT);
        require(this.players.has(msg.sender), ERROR_INVALID_PLAYER);
    }

    declareWinner(winnerAddress: Address, newGasFee: Int) {
        require(msg.sender == this.owner, ERROR_NOT_OWNER);
        require(!this.isFinished, ERROR_ALREADY_FINISHED);
        require(this.players.has(winnerAddress), ERROR_INVALID_WINNER);

        let totalPool = MIN_TON * 2;
        let commission = Math.muldiv(totalPool, COMMISSION_PERCENT, 100);
        let winnerAmount = totalPool - commission;

        this.isFinished = true;
        this.gasFee = newGasFee;

        // Send rewards
        send(SendParameters{
            to: winnerAddress,
            value: winnerAmount,
            mode: SendMode.PAY_GAS_SEPARATELY + SendMode.IGNORE_ERRORS,
            body: null,
        });

        // Send remaining balance to owner
        send(SendParameters{
            to: this.owner,
            value: commission - GAS_FEE,
            mode: SendMode.PAY_GAS_SEPARATELY + SendMode.IGNORE_ERRORS,
            body: null,
        });
    }

    refund(newGasFee: Int) {
        require(msg.sender == this.owner, ERROR_NOT_OWNER);
        require(!this.isFinished, ERROR_ALREADY_FINISHED);

        this.isFinished = true;
        this.gasFee = newGasFee;

        // Refund amount
        let refundAmount = MIN_TON;

        // Iterate through players and send refunds
        for ((playerAddress, _), _) in this.players.entries() {
            send(SendParameters{
                to: playerAddress,
                value: refundAmount,
                mode: SendMode.PAY_GAS_SEPARATELY + SendMode.IGNORE_ERRORS,
                body: null,
            });
        }
    }

    // Set Gas Fee
    setGasFee(newGasFee: Int) {
        require(msg.sender == this.owner, ERROR_NOT_OWNER);
        this.gasFee = newGasFee;
    }

    get fun getStorage(): Storage {
        return Storage{
            owner: this.owner,
            players: this.players,
            isFinished: this.isFinished,
            gasFee: this.gasFee,
        };
    }

    getOwner(): Address {
        return this.owner;
    }

    getPlayers(): Map<Address, Bool> {
        return this.players;
    }

    getIsFinished(): Bool {
        return this.isFinished;
    }

    getGasFee(): Int {
        return this.gasFee;
    }
}