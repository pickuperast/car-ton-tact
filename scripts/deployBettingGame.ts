import { toNano } from '@ton/core';
import { BettingGame } from '../wrappers/BettingGame';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const bettingGame = provider.open(await BettingGame.fromInit());

    await bettingGame.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(bettingGame.address);

    // run methods on `bettingGame`
}
