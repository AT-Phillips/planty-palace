import { defineSecret } from "firebase-functions/params";

// Real values are set once via `firebase functions:secrets:set <NAME>` and
// never touch the Flutter client build again.
export const plantNetApiKey = defineSecret("PLANTNET_API_KEY");
export const perenualApiKey = defineSecret("PERENUAL_API_KEY");
export const openWeatherApiKey = defineSecret("OPENWEATHER_API_KEY");
