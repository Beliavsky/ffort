#!/usr/bin/env python3
"""Execute frozen INQUIRE contracts with exclusive evidence and exact provenance."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
from validate_results import validate, stage_errors, input_inventory

ROOT = Path(__file__).resolve().parent

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def reserve_output(path):
    """Walk via directory descriptors, refusing symlinks and existing leaves."""
    absolute = Path(os.path.abspath(path))
    fd = os.open('/', os.O_RDONLY | os.O_DIRECTORY)
    try:
        for part in absolute.parts[1:-1]:
            next_fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd)
            fd = next_fd
        result = os.open(absolute.name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                         0o600, dir_fd=fd)
    finally:
        os.close(fd)
    return absolute, os.fdopen(result, 'w', encoding='utf-8', newline='\n')

def capture(argv, cwd):
    command = [str(x) for x in argv]
    timeout, spawn_error = False, None
    try:
        value = subprocess.run(command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            stdin=subprocess.DEVNULL, timeout=30, env=dict(os.environ, LC_ALL='C'))
        status, stdout, stderr = value.returncode, value.stdout, value.stderr
    except subprocess.TimeoutExpired as exc:
        status, stdout, stderr, timeout = None, exc.stdout or b'', exc.stderr or b'', True
    except OSError as exc:
        status, stdout, stderr, spawn_error = None, b'', b'', type(exc).__name__ + ': ' + str(exc)
    valid_utf8 = True
    try:
        text_out, text_err = stdout.decode('utf-8'), stderr.decode('utf-8')
    except UnicodeDecodeError:
        valid_utf8 = False
        text_out = stdout.decode('utf-8', errors='replace')
        text_err = stderr.decode('utf-8', errors='replace')
    return dict(argv=command, cwd=str(cwd), status=status, stdout=text_out, stderr=text_err,
        timeout=timeout, spawn_error=spawn_error, valid_utf8=valid_utf8,
        stdout_base64=base64.b64encode(stdout).decode('ascii'),
        stderr_base64=base64.b64encode(stderr).decode('ascii'),
        stdout_sha256=hashlib.sha256(stdout).hexdigest(), stderr_sha256=hashlib.sha256(stderr).hexdigest())

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe', type=Path, required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--results', type=Path, required=True)
    parser.add_argument('--gnu', type=Path, required=True)
    parser.add_argument('--gnu-sha256', required=True)
    args = parser.parse_args()
    output, stream = reserve_output(args.results)
    result = dict(status='failed_preserved', records=[])
    try:
        exe, gnu = args.exe.resolve(), args.gnu.resolve()
        manifest = json.loads((ROOT/'manifest.json').read_text())
        result['inputs_before'] = input_inventory(ROOT, manifest)
        result['manifest_sha256'] = sha(ROOT/'manifest.json')
        result['runner_sha256'] = sha(ROOT/'run_tests.py')
        result['validator_sha256'] = sha(ROOT/'validate_results.py')
        result['candidate_sha256_before'] = sha(exe)
        result['gnu_sha256_before'] = sha(gnu)
        if result['gnu_sha256_before'] != args.gnu_sha256:
            raise ValueError('GNU executable differs from independently expected identity')
        if result['candidate_sha256_before'] != args.sha256:
            raise ValueError('Candidate executable identity differs')
        result['version_before'] = capture([exe, '--version'], ROOT)
        result['gnu_version'] = capture([gnu, '--version'], ROOT)
        with tempfile.TemporaryDirectory(prefix='inquire-strict-') as temporary:
            work = Path(temporary)
            result['execution_cwd'] = str(work)
            input_path = work/manifest['registered_name']
            input_path.write_bytes(manifest['input_data'].encode('utf-8'))
            result['input_bytes_sha256_before'] = sha(input_path)
            binding = '17=' + manifest['registered_name']
            for case in manifest['cases']:
                source = (ROOT/case['source']).resolve()
                row = {key:case[key] for key in ('name','source','sha256','gnu_mode')}
                result['records'].append(row)
                if sha(source) != case['sha256']:
                    raise ValueError('Fixture identity differs: ' + case['name'])
                row['check'] = capture([exe,'--check','--input',binding,source],work)
                row['run'] = capture([exe,'--input',binding,source],work)
                raw = source.read_bytes()
                setup = ("open(unit=iu,file='"+manifest['registered_name']+"',status='old',action='read')").encode()
                adapted = raw.replace(b'! GNU_REGISTER_INPUT',setup)
                oracle, binary = work/'oracle.f90', work/'oracle'
                oracle.write_bytes(adapted)
                row['oracle_source_latin1'] = adapted.decode('latin1')
                row['oracle_sha256'] = hashlib.sha256(adapted).hexdigest()
                row['gnu_compile'] = capture([gnu,'-std=f2018','-pedantic-errors','-O0','-fcheck=all',
                    '-ffree-line-length-none',oracle,'-o',binary],work)
                row['gnu_run'] = None
                if case['gnu_mode']=='execute' and not stage_errors(row['gnu_compile']):
                    if row['gnu_compile']['status']==0 and row['gnu_compile']['stdout']=='' and row['gnu_compile']['stderr']=='':
                        row['gnu_run'] = capture([binary],work)
            source = (ROOT/manifest['cases'][0]['source']).resolve()
            missing = '17=missing-input-must-not-open.dat'
            result['missing_input_check'] = capture([exe,'--check','--input',missing,source],work)
            result['missing_input_run'] = capture([exe,'--input',missing,source],work)
            result['input_bytes_sha256_after'] = sha(input_path)
        result['version_after'] = capture([exe,'--version'],ROOT)
        result['candidate_sha256_after'] = sha(exe)
        result['gnu_sha256_after'] = sha(gnu)
        result['inputs_after'] = input_inventory(ROOT,manifest)
        result['validation_errors'] = validate(result,manifest,ROOT,args.sha256,args.gnu_sha256)
        if not result['validation_errors']:
            result['status']='passed'
    except Exception as exc:
        result['runner_exception'] = type(exc).__name__ + ': ' + str(exc)
    finally:
        json.dump(result,stream,indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
        stream.close()
    print(output)
    for error in result.get('validation_errors',[]):
        print(error)
    if result.get('runner_exception'):
        print(result['runner_exception'])
    return 0 if result['status']=='passed' else 1

if __name__=='__main__':
    raise SystemExit(main())
