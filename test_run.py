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
    # 'teamcity.build.branch': 'develop',
    'teamcity.build.branch': 'pull/1',
    # 'teamcity.build.branch': 'feature/BLOG-123',
    'vcsroot.url': 'https://github.com/zhiltsov-sigma/jira-hooks.git',
    'system.teamcity.buildType.id': 'JiraHooks_TestBuild',
    'teamcity.serverUrl': 'http://10.40.102.254:8111',
    'build.vcs.number': '3f16fc958fd2c44799fca9cf13c63995aeaf5e52',
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
