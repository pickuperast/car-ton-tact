import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/betting_game.tact',
    options: {
        debug: true,
    },
};
