import "@stdlib/deploy";

contract RacingGame with Deployable{
    owner: Address;
    players: map<Address, Int>;
    gameOver: Bool;
    
    init(owner: Address) {
        self.owner = sender();
        self.players = emptyMap();
        self.gameOver = false;
    }

    // Players send money to participate
    receive("deposit") {
        require(!self.gameOver, "Game is over");
        let sender = my_address();
        let amount = my_balance();

        let currentAmount: Int = self.players.get(sender, 0);
        self.players.set(sender, currentAmount + amount);
    }

   // Owner declares the winner and refunds money
    receive("declare_winner") {
        let winner = get_msg_address();  // Extract winner from the message
        require(my_address() == self.owner, "Only owner can declare winner");
        require(!self.gameOver, "Game already finished");

        self.gameOver = true;
        let totalPrize = sum(self.players.values());

        send(winner, totalPrize);
    }
}
