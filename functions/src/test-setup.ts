import { getApps, initializeApp } from "firebase-admin/app";

// Shared across test files in the same mocha process - initializeApp()
// throws if called more than once with the default app name.
if (getApps().length === 0) {
  initializeApp({ projectId: "planty-palace-test" });
}
