import os
import stat
from subprocess import call

dir_path = os.path.dirname(os.path.realpath(__file__))
in_file = os.path.join(dir_path, 'run.sh')
out_file = os.path.join(dir_path, 'run_exec.sh')


def include_templates(body):
    return body


with open(in_file, 'r') as file:
    content = file.read()
    exec_content = include_templates(content)

    with open(out_file, 'w+') as outp:
        outp.write(exec_content)

    os.chmod(out_file, os.stat(out_file).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

call([out_file])
