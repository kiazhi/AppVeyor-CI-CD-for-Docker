# Display Python version
python --version

# Display Python help
python --help

# Use Python to execute some python code to gather system information and
# display it on the console
python -c "import platform, os, socket, ipaddress; print('Platform Hostname  : ' + platform.node() + '\n' + 'Platform Version   : ' + platform.system() + ' ' + platform.version() + '\n' + 'Platform Machine   : ' + str(platform.machine()) + '\n' + 'Platform Processor : ' + platform.processor() + '\n' + 'Platform IP Address: ' + socket.gethostbyname(socket.gethostname()) + '\n' + 'Python Compiler    : ' + platform.python_compiler() + '\n' + 'Python Version     : ' + platform.python_version() + '\n' + 'Python Build       : ' + str(platform.python_build()) + '\n\n')"