// //////////////
//
// extract-export-logs.js
//
// //////
//
// (c) 2021, LogRhythm
//
// //////
//
// tony.masse@logrhythm.com
//
// //////
// Versions:
//
// v1 - 2021.05.21 - tony.masse@logrhythm.com
// - Initial version
// v2 - 2021.05.22 - tony.masse@logrhythm.com
// - Better logging
// v3 - 2021.05.23 - tony.masse@logrhythm.com
// - More verbose logging

// Steps:
// (steps 1. to 3.1. are done before this script)
// 1. AWS CLI S3 Sync > sync_log.txt
// 2. parse sync_log.txt to extract the name of the newly downloaded file
// 3. For each of these file name
//   3.1 gunzip to a temp file
//   3.2 extract each log from temp file
//     3.2.1 stringify log into a single line
//     3.2.2 append single line JSON log into filebeat input file(/var/export / jc / input_XYZ.log)

const fs = require('fs');
const path = require('path');

// Get arguments
const cmdArguments = process.argv.slice(2);
if (cmdArguments.length < 3) {
  console.log('ERROR - Missing arguments.');
  console.log('Must be provided:');
  console.log(' - Name of the file containing the JSON array');
  console.log(' - Full path of the directory where to write the itemised logs');
  console.log(' - Name of the original compressed file');
  process.exit(1);
}

const jsonArrayFileName = cmdArguments[0];
const targetPath = cmdArguments[1];
const originalCompressedFileName = cmdArguments[2];

// Create the new output file
const newLogFile = path.join(targetPath, String(originalCompressedFileName).replace(/\.gz$/, '.log').replace(/[\\\/:]/g, '_'));

// Read up the Temp file
const logArray = JSON.parse(fs.readFileSync(jsonArrayFileName, 'utf8'));

if (Array.isArray(logArray)) {
  //   3.2 extract each log from temp file
  logArray.forEach((log) => {
    try {
      //     3.2.1 stringify log into a single line
      //     3.2.2 append single line JSON log into filebeat input file(/var/export / jc / input_XYZ.log)
      fs.appendFile(newLogFile, JSON.stringify(log) + '\n', 'utf8', (err) => {
        if (err) {
          console.log('ERROR - Could not write (append data) to ' + newLogFile + '. Reason: ' + err);
        }
      });
    } catch {
      console.log('ERROR - Could not write (append data) to ' + newLogFile);
    }
  })

} else {
  console.log('ERROR - Provided file does not contain a JSON Array. Exiting.');
  process.exit(1);
}
