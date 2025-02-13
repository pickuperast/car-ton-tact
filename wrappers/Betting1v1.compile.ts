import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/betting_1v1.tact',
    options: {
        debug: true,
    },
};
