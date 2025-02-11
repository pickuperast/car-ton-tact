import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { BettingGame } from '../wrappers/BettingGame';
import '@ton/test-utils';

describe('BettingGame', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let bettingGame: SandboxContract<BettingGame>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        bettingGame = blockchain.openContract(await BettingGame.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await bettingGame.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: bettingGame.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and bettingGame are ready to use
    });
});
