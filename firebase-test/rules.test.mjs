import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  deleteDoc,
} from 'firebase/firestore';

/**
 * Security-rules tests for the Thicket Firestore database.
 *
 * These run against the Firestore emulator, so they exercise the real rules
 * engine against the real firestore.rules file - the only way to actually
 * demonstrate that one signed-in user cannot read another's plants. A rules
 * file that merely *compiles* proves nothing about who can read what.
 *
 * Run from the repo root:  npm --prefix firebase-test test
 */

const ALICE = 'alice-uid';
const BOB = 'bob-uid';

let testEnv;

/** Every collection path the app actually reads or writes, relative to a user. */
const USER_PATHS = [
  ['gardens', 'garden-1'],
  ['plants', 'plant-1'],
  ['care_log', 'log-1'],
  ['propagations', 'prop-1'],
  ['wishlist', 'item-1'],
];

/** Nested paths, which the recursive rule must also cover. */
const NESTED_PATHS = [
  ['plants/plant-1/photos', 'photo-1'],
  ['plants/plant-1/journal', 'entry-1'],
  ['propagations/prop-1/photos', 'photo-1'],
];

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'thicket-rules-test',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

describe('a signed-in user, in their own subtree', () => {
  it('can write and read every collection the app uses', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();

    for (const [path, id] of [...USER_PATHS, ...NESTED_PATHS]) {
      const ref = doc(db, `users/${ALICE}/${path}/${id}`);
      await assertSucceeds(setDoc(ref, { name: 'Monstera' }));
      await assertSucceeds(getDoc(ref));
    }
  });

  it('can list a collection and delete a document', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();

    await assertSucceeds(
      setDoc(doc(db, `users/${ALICE}/plants/doomed`), { name: 'Fern' }),
    );
    await assertSucceeds(getDocs(collection(db, `users/${ALICE}/plants`)));
    await assertSucceeds(deleteDoc(doc(db, `users/${ALICE}/plants/doomed`)));
  });
});

describe("another signed-in user's subtree", () => {
  it('cannot be read, at any depth', async () => {
    const db = testEnv.authenticatedContext(BOB).firestore();

    for (const [path, id] of [...USER_PATHS, ...NESTED_PATHS]) {
      await assertFails(getDoc(doc(db, `users/${ALICE}/${path}/${id}`)));
    }
  });

  it('cannot be listed', async () => {
    const db = testEnv.authenticatedContext(BOB).firestore();
    await assertFails(getDocs(collection(db, `users/${ALICE}/plants`)));
  });

  it('cannot be written to or deleted', async () => {
    const db = testEnv.authenticatedContext(BOB).firestore();

    await assertFails(
      setDoc(doc(db, `users/${ALICE}/plants/plant-1`), { name: 'stolen' }),
    );
    await assertFails(deleteDoc(doc(db, `users/${ALICE}/plants/plant-1`)));
  });

  it('cannot read the user document itself', async () => {
    const db = testEnv.authenticatedContext(BOB).firestore();
    await assertFails(getDoc(doc(db, `users/${ALICE}`)));
  });
});

describe('an unauthenticated client', () => {
  it('cannot read or write anything', async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(getDoc(doc(db, `users/${ALICE}/plants/plant-1`)));
    await assertFails(
      setDoc(doc(db, `users/${ALICE}/plants/plant-1`), { name: 'nope' }),
    );
    await assertFails(getDocs(collection(db, `users/${ALICE}/plants`)));
  });
});

describe('anonymous sign-in', () => {
  it('is treated as a real owner', async () => {
    // The app signs every install in anonymously and only later links an
    // email to that same uid, so anonymous users must have full access to
    // their own data - otherwise most users could not use the app at all.
    const anon = testEnv
      .authenticatedContext('anon-uid', { provider_id: 'anonymous' })
      .firestore();

    const ref = doc(anon, 'users/anon-uid/plants/plant-1');
    await assertSucceeds(setDoc(ref, { name: 'Pilea' }));
    await assertSucceeds(getDoc(ref));
  });
});

describe('paths outside the per-user subtree', () => {
  it('are denied even to a signed-in user', async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();

    // Nothing in the app reads or writes a top-level collection, so the
    // absence of a catch-all rule should close these off entirely.
    await assertFails(getDoc(doc(db, 'plants/plant-1')));
    await assertFails(setDoc(doc(db, 'plants/plant-1'), { name: 'nope' }));
    await assertFails(setDoc(doc(db, 'config/flags'), { beta: true }));
    assert.ok(true);
  });
});
