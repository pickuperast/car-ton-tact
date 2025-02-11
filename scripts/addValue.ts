import { toNano } from '@ton/core';
import { BettingGame } from '../wrappers/BettingGame';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const contractId = 1648n;
    const bettingGame = provider.open(await BettingGame.fromInit(contractId));

    const id = await bettingGame.getId();
    const counter = await bettingGame.getNumber();

    console.log(`Sending increasing value...`);
    console.log(`Contract ID: ${id}`);
    console.log(`Current counter: ${counter}`);

    // Call the Add function and add 7
    await bettingGame.send(provider.sender(), { value: toNano('0.02') }, { $$type: 'Save', amount: 7n });
}

