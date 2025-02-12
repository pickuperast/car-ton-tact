import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { BettingGame } from '../wrappers/BettingGame';
import '@ton/test-utils';

// On TON we can test by creating a virtual chain
describe('BettingGame', () => {
    let blockchain: Blockchain; // Init a virtual chain
    let deployer: SandboxContract<TreasuryContract>;
    let bettingGame: SandboxContract<BettingGame>; // Init the smart contract instance

    const contractId = 1648n; // Id for deployment that will be passed in the contructor. Random value in this example

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        bettingGame = blockchain.openContract(await BettingGame.fromInit(contractId));

        // Init the deployer. It comes with 1M TON tokens
        deployer = await blockchain.treasury('deployer');

        const deployResult = await bettingGame.send(
            deployer.getSender(),
            {
                value: toNano('0.05'), // Value to send to the contract
            },
            {
                $$type: 'Deploy', // This because the contract inherits the Deployable trait.
                queryId: 0n,
            },
        );

        // Here is the test. In this case it tests that the contract is deployed correctly.
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
        console.log('Deploying contract...');

        const conttactId = await bettingGame.getId();
        console.log(`Fetched ID during deployment: ${conttactId}`);
    });

    it('should increase', async () => {
        console.log('Testing increase by 1 function...');
        const counterBefore = await bettingGame.getCounter();

        console.log('counterBefore - ', counterBefore);

        await bettingGame.send(
            deployer.getSender(),
            {
                value: toNano('0.02'),
            },
            'add 1', // The message the contract expects
        );

        const counterAfter = await bettingGame.getCounter();

        console.log('counterAfter - ', counterAfter);

        // Check it incremented the value
        expect(counterBefore).toBeLessThan(counterAfter);
    });

    it('should increase by 3', async () => {
        console.log('Testing increase by 3 function...');
        const counterBefore = await bettingGame.getCounter();

        console.log('counterBefore - ', counterBefore);

        await bettingGame.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            'add 3', // The message the contract expects
        );

        const counterAfter = await bettingGame.getCounter();

        console.log('counterAfter - ', counterAfter);

        // Check it incremented the value
        expect(counterBefore).toBeLessThan(counterAfter);
    });

    it('should save the amount', async () => {
        console.log('Testing increase by given value function...');

        const numeberBefore = await bettingGame.getNumber();

        const amount = 10n;
        console.log(`Value to save: ${amount}`);
        console.log(`Number saved before: ${numeberBefore}`);

        await bettingGame.send(
            deployer.getSender(),
            {
                value: toNano('0.02'),
            },
            {
                $$type: 'Save', // This time it's an object and not just text
                amount: amount,
            },
        );

        const numberAfter = await bettingGame.getNumber();

        console.log(`Number saved after: ${numberAfter}`);
    });
});

