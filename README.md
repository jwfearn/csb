# Shipment Bundling

One problem that truckers face is having to find work that minimizes the number of miles they drive empty (aka _dead-heading_). Empty miles add to fuel costs, and are an opportunity cost - they could be driving that same distance hauling freight.

**Convoy** wants to help by automatically bundling shipments that we offer to truck drivers. This would make getting work from Convoy easier than getting work from multiple sources, and ensure drivers make more money when working with us. We receive hundreds of shipments per day, which gives plenty of opportunity to group them.

We'd like you to implement a V1 shipment bundler in a language of your choice.

## Spec for V1

Given a file with a single week’s worth of shipments (Monday through Friday), find the fewest number of bundles to offer to carriers.

A shipment bundle is a chronologically ordered sequence of shipments, where each shipment's `START_CITY` is the same as the previous one’s `END_CITY`, and their days are sequential and consecutive (e.g. `M-T-W` is okay, `M-F` is not). Every shipment should be in exactly one bundle, and bundles of one shipment are okay. In the case of a tie (multiple optimal solutions of N bundles), any solution is acceptable.

Your program should take the form of
```
<run command> <input file name>
```

### Input file

Each line in the file represents one shipment, and looks like:
```
<SHIPMENT_ID> <START_CITY> <END_CITY> <DAY_OF_WEEK>
```
`SHIPMENT_ID`s are integers, cities are single words (e.g. `SAN_FRANCISCO`), and the days of the week are

* `M` - Monday
* `T` - Tuesday
* `W` - Wednesday
* `R` - Thursday
* `F` - Friday

### Output (stdout)
The output of your program should be to `stdout`. Each line represents one shipment bundle as a series of shipment IDs, each separated by a space. The shipments in each bundle should be ordered chronologically, earliest to latest. The order of the lines in the file does not matter.

### Example

Here is a sample input file of 6 shipments:
```
1 SEATTLE PORTLAND M
2 PORTLAND SAN_FRANCISCO T
3 PORTLAND DENVER T
22 SEATTLE DENVER R
44 DENVER SEATTLE W
99 DENVER KANSAS_CITY F
```
And here is a sample output file for the above input which bundles the 5 shipments into 2 bundles:
```
3 44 22 99
1 2
```
You can see that
1. Every shipment is in exactly one bundle.
2. Shipments within a bundle are ordered chronologically.
3. Shipments within a bundle pick up at the place the previous one left off.
4. There are no gaps in the days between shipments.

### Testing your code

We've provided a small test program for validating your output, a series of test inputs and some answers. When evaluating your program, we will run these tests against your program.  If you add tests of your own, please include them with your submission.

The test program, described below, is configured with a timeout to ensure your solution completes in a reasonable amount of time. Keep this in mind when testing your algorithm.

#### Setup

Install `node` (>= 6)

#### Running tests

To run a test:
```
node validate.js "<run command for your program>" <test files>…
```

E.g. for a Node script, you might run:
```sh
node validate.js "node shipment_bundler.js" tests/*
```

If there is a corresponding entry in [`answers.json`](./answers.json) for the test, the test will also assert that your output matches the expected number of shipment bundles expressed by that file.

## What to submit

Please make sure you include all of the following in your submission:

1. Program source code
2. Very specific instructions on how to build and run your program from a command line.
3. Any additional tests you've created
