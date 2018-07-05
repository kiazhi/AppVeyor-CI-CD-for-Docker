# Display Nodejs version
node --version

# Display Nodejs help
node --help

# Use Nodejs to execute some javascript code to gather system information and
# display it on the console
node -e "var os = require('os'), dns = require('dns') ; console.log('Platform Hostname  : ' + os.hostname()) ; console.log('Platform Version   : ' + os.type() + ' ' + os.release()) ; console.log('Platform Machine   : ' + os.arch()) ; console.log('Platform Processor : ' + os.cpus()[0].model) ; dns.lookup(os.hostname(),(err,ipAddress) => {console.log('Platform IP Address: ' + ipAddress)}) ; console.log('Nodejs v8 Compiler : ' + process.versions.v8) ; console.log('Nodejs Version     : ' + process.version);"