import os
import logging

import robotjudge.constants as rc


def setup(debug_level: str = rc.DEBUG_LEVEL_DEFAULT):
    def print_header():
        header_file = os.path.join(rc.ENV_OPS_PATH, "install", "header.bash")
        os.system("bash " + header_file)

    def set_logging(level: str = rc.DEBUG_LEVEL_DEFAULT):
        logging_format = "[%(asctime)s]\t%(filename)30s:%(lineno)d\t%(levelname)s\t%(message)s"
        if level == "INFO":
            logging.basicConfig(format=logging_format, level=logging.INFO)
        elif level == "DEBUG":
            logging.basicConfig(format=logging_format, level=logging.DEBUG)
        elif level == "WARNING":
            logging.basicConfig(format=logging_format, level=logging.WARNING)
        else:
            raise ValueError("Invalid debug level {}".format(level))

    print_header()
    set_logging(debug_level)
