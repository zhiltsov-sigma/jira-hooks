import os
import stat
import subprocess
from subprocess import call

dir_path = os.path.dirname(os.path.realpath(__file__))
in_file = os.path.join(dir_path, 'run.sh')
out_file = os.path.join(dir_path, 'run_exec.sh')


def get_outp(*args):
    return subprocess.Popen(args,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE).communicate()[0]


tc_dictionary = {
    'teamcity.build.branch': 'develop',
    'system.teamcity.buildType.id': 'JiraHooks_TestBuild',
    'teamcity.serverUrl': 'http://10.40.102.254:8111',
    'build.vcs.number': '981eec47e4e17d14ec5a8e92b4270a92adff8196',
}


def include_templates(body):
    for k, v in tc_dictionary.items():
        body = body.replace('%{template}%'.format(template=k), v)
    return body


with open(in_file, 'r') as file:
    content = file.read()
    exec_content = include_templates(content)

    with open(out_file, 'w+') as outp:
        outp.write(exec_content)

    os.chmod(out_file, os.stat(out_file).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

call([out_file])
