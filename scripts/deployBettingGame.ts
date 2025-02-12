import { toNano } from '@ton/core';
import { BettingGame } from '../wrappers/BettingGame';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
  
  	// Edit this ID
    const contractId = 1648n;
    const bettingGame = provider.open(await BettingGame.fromInit(contractId));

    await bettingGame.send(
        provider.sender(),
        {
            value: toNano('0.5'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    // Deploy contract
    await provider.waitForDeploy(bettingGame.address);
    console.log(`Deployed at address ${bettingGame.address}`);

    // run methods on `bettingGame`
}
