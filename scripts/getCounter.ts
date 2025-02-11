import { BettingGame } from '../wrappers/BettingGame';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const contractId = 1648n; // Random in this case
    const bettingGame = provider.open(await BettingGame.fromInit(contractId));

    const id = await bettingGame.getId();
    const savedNumber = await bettingGame.getNumber();
    const counter = await bettingGame.getCounter();

    console.log(`Fethching smart contract data...`);
    console.log(`Contract ID: ${id}`);
    console.log(`Current saved number: ${savedNumber}`);
    console.log(`Current counter: ${counter}`);
}

