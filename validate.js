const childProcess = require('child_process');
const path = require('path');
const fs = require('fs');

const ANSWERS_FILE = process.env.ANSWERS
  ? path.resolve(process.env.ANSWERS)
  : path.join(__dirname, './answers.json');
const ANSWERS = require(ANSWERS_FILE);

const NEXT_DAY = {
  M: 'T',
  T: 'W',
  W: 'R',
  R: 'F',
};

const EXECUTION_TIMEOUT_SECONDS = 60;

// Glorious type safety

/**
 * @typedef {'M' | 'T' | 'W' | 'R' | 'F'} DayOfWeek
 */

/**
 * @typedef {string[]} Bundle
 */

/**
 * @typedef {Object} Shipment
 * @property {string} id
 * @property {string} start
 * @property {string} finish
 * @property {DayOfWeek} day
 */

// Actual script beginneth

if (process.argv.length < 4) {
  console.error(`Usage: node validate.js "QUOTED COMMAND TO RUN" FILES TO TEST`);
  process.exit(1);
}
runAllTests(process.argv[2], process.argv.slice(3));

/**
 * @param {string} runCommand
 * @param {string[]} tests
 */
function runAllTests(runCommand, tests) {
  let success = true;
  for (const test of tests) {
    if (!runTest(runCommand, path.resolve(test))) {
      success = false;
    }
  }
  console.log(``); // Extra visual margin to balance things out.

  process.exit(success ? 0 : 1);
}

/**
 * @param {string} runCommand
 * @param {string} test
 */
function runTest(runCommand, test) {
  let input;
  try {
    input = fs.readFileSync(test).toString();
  } catch (error) {
    console.error(`${test} does not appear to be a test file`);
    return false;
  }

  const command = `${runCommand} "${test}"`;
  console.log(`\nTesting: ${command}:`);
  const start = Date.now();
  let output;
  try {
    output = childProcess.execSync(`${runCommand} "${test}"`, {
      timeout: EXECUTION_TIMEOUT_SECONDS * 1e3,
    }).toString();
  } catch (error) {
    if (error.code === 'ETIMEDOUT') {
      console.error(`\n  The command timed out after ${EXECUTION_TIMEOUT_SECONDS} seconds`);
    }
    return false;
  }
  const duration = Date.now() - start;

  const inputShipments = parseInputShipments(input);
  const outputBundles = parseWords(output);
  const expectedBundleCount = ANSWERS[path.relative(path.dirname(ANSWERS_FILE), test)];

  const valid = validateResults(inputShipments, outputBundles, expectedBundleCount);
  if (valid) {
    if (expectedBundleCount) {
      console.log(`\n  Success! ${expectedBundleCount} valid bundles in ${duration}ms`);
    } else {
      console.log(`\n  Success! Shipment bundler ran in ${duration}ms`);
    }
  }

  return valid;
}

/**
 * @param {Shipment[]} shipments
 * @param {Bundle[]} outputBundles
 * @param {number} expectedBundleCount
 */
function validateResults(shipments, outputBundles, expectedBundleCount) {
  const outputIds = outputBundles.reduce((r, bundle) => r.concat(bundle), []);
  const inputIds = shipments.map(s => s.id);
  const shipmentsById = {};
  for (const shipment of shipments) {
    shipmentsById[shipment.id] = shipment;
  }

  const assertions = [
    assertNoDuplicates.bind(null, outputIds),
    assertEveryShipmentUsed.bind(null, inputIds, outputIds),
    assertAllBundlesValid.bind(null, shipmentsById, outputBundles),
    expectedBundleCount && assertCorrectNumberOfBundles.bind(null, outputBundles, expectedBundleCount),
  ];

  let success = true;
  for (const validation of assertions) {
    if (validation && !validation()) {
      success = false;
    }
  }
  return success;
}

// Assertions

/**
 * @param {string[]} outputIds
 */
function assertNoDuplicates(outputIds) {
  const duplicateIds = duplicateValues(outputIds);
  if (!duplicateIds.length) return true;

  console.error(`\n  Expected shipments to not occur in multiple bundles:`);
  for (const id of duplicateIds) {
    console.error(`    Duplicate id: ${id}`);
  }
  return false;
}

/**
 * @param {string[]} inputIds
 * @param {string[]} outputIds
 */
function assertEveryShipmentUsed(inputIds, outputIds) {
  const lookups = new Set(outputIds);
  const missingIds = inputIds.filter(id => !lookups.has(id));
  if (!missingIds.length) return true;

  console.error(`\n  Expected all shipments to be used in a bundle:`)
  missingIds.forEach(id => {
    console.error(`    Missing shipment: ${id}`);
  });

  return false;
}

/**
 * @param {Object<string, Shipment>} shipmentById
 * @param {Bundle[]} outputBundles
 */
function assertAllBundlesValid(shipmentById, outputBundles) {
  let allValid = true;

  for (const bundle of outputBundles) {
    const messages = [];

    const shipments = [];
    for (const shipmentId of bundle) {
      const shipment = shipmentById[shipmentId];
      if (!shipment) {
        messages.push(`Unknown shipment: ${shipmentId}`);
      }
      shipments.push(shipment);
    }

    // Don't bother checking the bundles if we're referencing unknown shipments.
    if (!messages.length) {
      for (let i = 1; i < shipments.length; i++) {
        const previous = shipments[i - 1];
        const current = shipments[i];
        if (previous.finish !== current.start) {
          messages.push(`Shipment ${previous.id}'s finish (${previous.finish}) differs from ${current.id}'s start (${current.start})`);
        }
        if (previous.finish !== current.start) {
          messages.push(`Shipment ${previous.id} (${previous.day}) does not occur the day before shipment ${current.id} (${current.day})`);
        }
      }
    }

    if (messages.length) {
      allValid = false;
      console.error(`\n  Invalid bundle [${bundle.join(', ')}]:`);
      for (const message of messages) {
        console.error(`    ${message}`);
      }
    }
  }

  return allValid;
}

/**
 * @param {*} outputBundles
 * @param {*} expectedAnswers
 */
function assertCorrectNumberOfBundles(outputBundles, expectedAnswers) {
  const correct = outputBundles.length === expectedAnswers;
  if (!correct) {
    console.error(`\n  Expected ${expectedAnswers} bundles; got ${outputBundles.length}`);
  }
  return correct;
}

// Helpers

/**
 * Parses a test input file, where each line is of the format:
 *
 *   <id> <start> <finish> <day>
 *
 * @param {string} contents
 */
function parseInputShipments(contents) {
  return parseWords(contents).map(line => ({
    id: line[0],
    start: line[1],
    finish: line[2],
    day: line[3],
  }));
}

/**
 * @param {string} contents
 */
function parseWords(contents) {
  return contents
    .split('\n')
    .map(line => line.trim())
    .filter(line => line !== '')
    .map(line => line.split(' '));
}

/**
 * @param {string[]} values
 */
function duplicateValues(values) {
  const countsByValue = {};
  for (const value of values) {
    countsByValue[value] = (countsByValue[value] || 0) + 1;
  }

  const duplicates = [];
  for (const value in countsByValue) {
    if (countsByValue[value] < 2) continue;
    duplicates.push(value);
  }

  return duplicates;
}
