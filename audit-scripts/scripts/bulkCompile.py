import os
import sys
from subprocess import Popen, PIPE


CONTRACTS_ROOT_DIR = "../PlexusContracts/contracts"
LOGFILE_DIR = "./outputs/logs"
LOGFILE = "compilation"
COMPILER = "solcjs"

if len(sys.argv) > 1 and sys.argv[1] in ["--bin", "--abi"]:
    MODE = sys.argv[1]
else:
    MODE = "--bin"

OUTPUTS_DIR = "./outputs/compiled_%s" % MODE.replace("--", "")
FLAGS = ["%s" % MODE, "--output-dir", OUTPUTS_DIR]
file_list = os.listdir(CONTRACTS_ROOT_DIR)
log = ""

try:
    # Handle File Exists Error
    os.mkdir(OUTPUTS_DIR)
except:
    pass

for _file in file_list:
    abs_target_file = os.path.join(CONTRACTS_ROOT_DIR, _file)
    pipe = Popen([COMPILER,*FLAGS, abs_target_file], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    #output = subprocess.call([COMPILER,*FLAGS, abs_target_file])
    output, err = pipe.communicate()
    pre_line_1 = "%s %s %s" % ("#" * 25, _file, "#" * 25)
    info_line = "\n\nOutput: %s \n\ Compilation_Error: %s \n\n" % (str(output).replace("\\n","\n") , str(err))
    post_line_1 = "#" * (50 + len(_file) + 2)
    log += "%s\n%s\n%s\n" % (pre_line_1, info_line, post_line_1)
    post_line_1 = "#" * (50 + len(_file) + 2)

with open(os.path.join(LOGFILE_DIR, "%s_%s.log" % (LOGFILE, MODE.replace("--",""))), "w") as my_fil:
    my_fil.write(log)
