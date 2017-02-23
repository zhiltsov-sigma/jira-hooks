import os

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

