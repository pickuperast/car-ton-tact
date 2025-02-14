import express, { Request, Response, NextFunction, query } from 'express';
import dotenv from 'dotenv';
import path from "path";
import TelegramBot, {
    CallbackQuery,
    InlineQuery,
    AnswerCallbackQueryOptions
} from "node-telegram-bot-api";
dotenv.config();

const TOKEN: string = process.env.TG_TOKEN || "";
const gameName: string = process.env.GAME_NAME || "";
const gameUrl: string = process.env.GAME_URL || "";
const port: number = parseInt(process.env.PORT || "5000");

const bot = new TelegramBot(TOKEN, { polling: true });
const server = express();
const queries: Record<string, CallbackQuery> = {};

server.use(express.static(path.join(__dirname, "Название корневой папки бэкэнда")));

bot.onText(/help/, async (msg) => {
    if (!msg.from) return;
    await bot.sendMessage(msg.from.id, "Say /game if you want to play.");
});

bot.onText(/start|game/, async (msg) => {
    if (!msg.from) return;
    await bot.sendGame(msg.from.id, gameName);
});

bot.on("callback_query", async (query: CallbackQuery) => {
    try {
        if (query.game_short_name !== gameName) {
            const options: AnswerCallbackQueryOptions = {
                callback_query_id: '',
                text: `Sorry, '${query.game_short_name}' is not available.`,
                show_alert: true
            };
            await bot.answerCallbackQuery(query.id, options);
        } else {
            queries[query.id] = query;
            const options: AnswerCallbackQueryOptions = {
                callback_query_id: '',
                url: gameUrl
            };
            await bot.answerCallbackQuery(query.id, options);
        }
    } catch (error) {
        console.error("Error handling callback query:", error);
    }
});

bot.on("inline_query", async (iq: InlineQuery) => {
    try {
        await bot.answerInlineQuery(iq.id, [
            {
                type: "game",
                id: "0",
                game_short_name: gameName
            }
        ]);
    } catch (error) {
        console.error("Error handling inline query:", error);
    }
});

server.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
