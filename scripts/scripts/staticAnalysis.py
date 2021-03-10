import os
import time
from pythx import Client
from utils import utils
import traceback
import argv

"""
['__abstractmethods__', '__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_abc_cache', '_abc_negative_cache', '_abc_negative_cache_version', '_abc_registry', 'decoded_locations', 'description_long', 'description_short', 'extra_data', 'from_dict', 'from_json', 'locations', 'severity', 'swc_id', 'swc_title', 'to_dict', 'to_json']
"""

AVAILABLE_MX_MODES = ["quick", "standard", "deep"]

if len(argv) > 1 and argv[1] in AVAILABLE_MX_MODES:
    ANALYSIS_MODE = argv[1]
else:
    ANALYSIS_MODE = "quick"

ROOT_BINARIES_DIR = "./outputs/compiled_bin"
OUTPUT_DIR = "./outputs/static_analysis_reports_%s" % ANALYSIS_MODE
environment : str = ""
binaries : str = ""


# File Dir Dirty Create
try:
    os.mkdir(OUTPUT_DIR)
except:
    traceback.print_exc()

# Script Set up
try:
    environment = utils.grabEnvFile()
    binaries = os.listdir("./outputs/compiled_bin")

except:
    raise Exception("Init Script Environment")

# Init Mythx Client

c = Client(api_key=environment.get("MYTHX_API_KEY"))
log_string =""

for byte_file in binaries:
    print("Analyzing: %s" % byte_file)

    byte: str = ""

    try:
        byte = str(open(os.path.join(ROOT_BINARIES_DIR, byte_file), "r").read())
        assert len(byte) > 0
    except:
        print("Data Error in: %s ... Skipping" % byte_file)
        continue

    # submit bytecode, source files, their AST and more!
    resp = c.analyze(bytecode=byte, analysis_mode=ANALYSIS_MODE)

    # wait for the analysis to finish
    while not c.analysis_ready(resp.uuid):
            time.sleep(1)

    # have all your security report data at your fingertips
    for issue in c.report(resp.uuid):
        print(c.report)
        print(resp.uuid)
        print(dir(issue))
        issue_dict = issue.to_dict()
        log_string += ("\n\n\n\n" + "\n".join(["%s : %s" % (k,issue_dict[k]) for k in issue_dict.keys()]) + "\n\n\n")
        #log_string += "\n\n\n\nTitle: %s\n\nDescription: %s \n\n\n\n" % (issue.swc_title or "Undefined", issue.description_long or "Undefined")

    LOG_FILE = byte_file.replace(".bin", ".report.txt")

    if len(log_string) <= 0:
        continue

    else:
        log_title= "\n\n%s\n\n\n %s \n\n\n%s\n\n" % (35 * "#", byte_file.replace(".bin",""), 35 * "#")
        log_string = log_title + log_string

    with open(os.path.join(OUTPUT_DIR, LOG_FILE), "w") as log_fil:
        log_fil.write(log_string)

    log_string =""
