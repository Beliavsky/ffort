"""Pure strict stage validation, independent of receipt self-reported success."""
import base64
import hashlib
import re
from pathlib import Path

CRASH = ('segmentation fault', 'sigsegv', 'sigabrt', 'sigfpe', 'backtrace', 'core dumped', 'runtime error:', 'internal compiler error', 'please submit a full bug report', 'double free', 'malloc():', 'free():', 'addresssanitizer', 'undefinedbehaviorsanitizer', 'traceback (most recent call last)', 'program received signal', 'runtimeerror:', 'fatal python error')

def stage_errors(stage):
    if type(stage) is not dict:
        return ['stage must be an object']
    errors = []
    if type(stage.get('cwd')) is not str or not stage['cwd']:
        errors.append('cwd must be a present nonempty string')
    argv = stage.get('argv')
    if type(argv) is not list or not argv or any(type(arg) is not str or not arg for arg in argv):
        errors.append('argv must be a present nonempty string list')
    if type(stage.get('status')) is not int or stage['status'] < 0:
        errors.append('status must be a nonnegative integer, never bool')
    for key in ('stdout', 'stderr'):
        value = stage.get(key)
        if type(value) is not str:
            errors.append(key + ' must be present string')
        elif '\ufffd' in value or any(0xD800 <= ord(c) <= 0xDFFF for c in value):
            errors.append(key + ' decoding corruption')
        elif any(marker in value.lower() for marker in CRASH):
            errors.append(key + ' crash marker')
    for key in ('stdout', 'stderr'):
        try:
            encoded=stage[key+'_base64']
            if type(encoded) is not str:
                raise ValueError('raw payload must be string')
            raw=base64.b64decode(encoded,validate=True)
            if base64.b64encode(raw).decode('ascii') != encoded:
                raise ValueError('raw payload is noncanonical')
            if hashlib.sha256(raw).hexdigest()!=stage.get(key+'_sha256'):
                raise ValueError('raw hash differs')
            if raw.decode('utf-8')!=stage.get(key):
                raise ValueError('decoded stream differs')
        except (KeyError,ValueError,UnicodeError,TypeError) as exc:
            errors.append(key+' raw bytes invalid: '+str(exc))
    if 'timeout' in stage and stage['timeout'] is not False:
        errors.append('timeout must be absent or bool False')
    if 'valid_utf8' in stage and stage['valid_utf8'] is not True:
        errors.append('valid_utf8 must be absent or bool True')
    if stage.get('spawn_error') is not None:
        errors.append('stage process did not spawn cleanly')
    return errors

def input_inventory(root, manifest):
    root=Path(root)
    names=['run_tests.py','validate_results.py','test_runner.py','manifest.json','original-statement-proof.json']
    names += [case['source'] for case in manifest['cases']]
    found={}
    for name in sorted(names):
        relative=Path(name)
        if relative.is_absolute() or '..' in relative.parts:
            raise ValueError('input path escapes suite')
        path=root/relative
        if path.is_symlink() or not path.is_file():
            raise ValueError('input must be regular non-symlink file: '+name)
        found[name]=hashlib.sha256(path.read_bytes()).hexdigest()
    return found

def validate(result, manifest, root, candidate_sha, gnu_sha):
    errors = []
    root = Path(root).resolve()
    if type(result) is not dict:
        return ['receipt must be an object']
    def stage(label, value, expected=None):
        found = stage_errors(value)
        errors.extend(label + ': ' + message for message in found)
        if found:
            return False
        if expected is not None:
            for key, wanted in expected.items():
                if value.get(key) != wanted:
                    errors.append(label + ': exact ' + key + ' contract differs')
        return True
    try:
        current=input_inventory(root,manifest)
    except (OSError,ValueError) as exc:
        return ['input inventory unavailable: '+str(exc)]
    for key in ('inputs_before','inputs_after'):
        if result.get(key)!=current:
            errors.append(key+' exact whole input identity differs')
    for key in ('gnu_sha256_before','gnu_sha256_after'):
        if type(result.get(key)) is not str or re.fullmatch(r'[0-9a-f]{64}',result[key]) is None:
            errors.append(key+' missing or malformed')
    if type(gnu_sha) is not str or re.fullmatch(r'[0-9a-f]{64}',gnu_sha) is None:
        errors.append('independently expected GNU identity missing or malformed')
    for key in ('gnu_sha256_before','gnu_sha256_after'):
        if result.get(key) != gnu_sha:
            errors.append(key+' differs from independently expected GNU identity')
    if result.get('gnu_sha256_before') != result.get('gnu_sha256_after'):
        errors.append('GNU executable changed during run')
    input_sha=hashlib.sha256(manifest['input_data'].encode()).hexdigest()
    for key in ('input_bytes_sha256_before','input_bytes_sha256_after'):
        if result.get(key)!=input_sha:
            errors.append(key+' registered data differs')
    work=result.get('execution_cwd')
    if type(work) is not str or not Path(work).is_absolute():
        errors.append('common execution cwd missing or malformed')
    if result.get('runner_exception') is not None:
        errors.append('runner exception recorded')
    for key, filename in (('runner_sha256', 'run_tests.py'), ('validator_sha256', 'validate_results.py')):
        if result.get(key) != hashlib.sha256((root / filename).read_bytes()).hexdigest():
            errors.append(key + ' policy identity differs')
    manifest_path = root / 'manifest.json'
    if result.get('manifest_sha256') != hashlib.sha256(manifest_path.read_bytes()).hexdigest():
        errors.append('manifest identity differs')
    def command(label, value, argv, cwd=None):
        if type(value) is not dict:
            return
        if value.get('argv') != argv:
            errors.append(label + ': exact invocation/phase differs')
        if type(value.get('cwd')) is not str or (cwd is not None and value['cwd'] != cwd):
            errors.append(label + ': invocation working directory differs')
    version = result.get('version_before', {})
    argv = version.get('argv') if type(version) is dict else None
    exe = argv[0] if type(argv) is list and len(argv) == 2 and type(argv[0]) is str else ''
    gv = result.get('gnu_version', {})
    ga = gv.get('argv') if type(gv) is dict else None
    gnu = ga[0] if type(ga) is list and len(ga) == 2 and type(ga[0]) is str else ''
    if not exe or not gnu:
        errors.append('compiler/candidate executable identity missing')
    for key in ('version_before', 'version_after'):
        command(key, result.get(key), [exe, '--version'], str(root))
    command('gnu_version', result.get('gnu_version'), [gnu, '--version'], str(root))
    for key in ('candidate_sha256_before', 'candidate_sha256_after'):
        if result.get(key) != candidate_sha:
            errors.append(key + ' differs')
    for key in ('version_before', 'version_after'):
        stage(key, result.get(key), {'status': 0, 'stdout': manifest['version_stdout'], 'stderr': ''})
    stage('gnu_version', result.get('gnu_version'), {'status': 0, 'stdout': manifest['gnu_version_stdout'], 'stderr': ''})
    rows = result.get('records')
    if type(rows) is not list or len(rows) != len(manifest['cases']):
        return errors + ['exact case inventory differs']
    for row, case in zip(rows, manifest['cases']):
        name = case['name']
        if type(row) is not dict:
            errors.append(name + ': row must be object')
            continue
        for key in ('name', 'source', 'sha256', 'gnu_mode'):
            if row.get(key) != case[key]:
                errors.append(name + ': ' + key + ' identity differs')
        source = root / case['source']
        try:
            raw = source.read_bytes()
        except OSError:
            errors.append(name + ': source missing')
            continue
        if hashlib.sha256(raw).hexdigest() != case['sha256']:
            errors.append(name + ': source hash differs')
        for phase in ('check', 'run'):
            contract = dict(case[phase + '_contract'])
            contract['stderr'] = contract['stderr'].replace('{source}', str(source))
            stage(name + '/' + phase, row.get(phase), contract)
            wanted_argv = [exe] + (['--check'] if phase == 'check' else []) + ['--input', '17=' + manifest['registered_name'], str(source)]
            command(name + '/' + phase, row.get(phase), wanted_argv, work)
        compile_result = row.get('gnu_compile')
        if stage(name + '/gnu_compile', compile_result):
            if case['gnu_mode'] == 'reject':
                expected_diagnostic=case['gnu_reject_stderr'].replace('{oracle}',str(Path(work)/'oracle.f90')) if type(work) is str else None
                if compile_result['status'] != 1 or compile_result['stdout'] != '' or compile_result['stderr'] != expected_diagnostic:
                    errors.append(name + ': GNU exact source-located rejection differs')
            elif compile_result['status'] != 0 or compile_result['stdout'] != '' or compile_result['stderr'] != '':
                errors.append(name + ': GNU compile must succeed silently')
        compile_cwd = compile_result.get('cwd') if type(compile_result) is dict else None
        if type(compile_cwd) is str:
            oracle = str(Path(compile_cwd) / 'oracle.f90')
            binary = str(Path(compile_cwd) / 'oracle')
            command(name + '/gnu_compile', compile_result, [gnu, '-std=f2018', '-pedantic-errors', '-O0', '-fcheck=all', '-ffree-line-length-none', oracle, '-o', binary], work)
            if case['gnu_mode'] == 'execute':
                command(name + '/gnu_run', row.get('gnu_run'), [binary], compile_cwd)
        if case['gnu_mode'] == 'execute':
            stage(name + '/gnu_run', row.get('gnu_run'), {'status': 0, 'stdout': case['expected_stdout'], 'stderr': ''})
        elif row.get('gnu_run', 'missing') is not None:
            errors.append(name + ': GNU must not execute compile-only/rejected source')
        setup = ("open(unit=iu,file='" + manifest['registered_name'] + "',status='old',action='read')").encode()
        adapted = raw.replace(b'! GNU_REGISTER_INPUT', setup)
        if row.get('oracle_source_latin1') != adapted.decode('latin1') or row.get('oracle_sha256') != hashlib.sha256(adapted).hexdigest():
            errors.append(name + ': exact GNU setup adaptation differs')
    first = root / manifest['cases'][0]['source']
    command('missing_input_check', result.get('missing_input_check'), [exe, '--check', '--input', '17=missing-input-must-not-open.dat', str(first)], work)
    command('missing_input_run', result.get('missing_input_run'), [exe, '--input', '17=missing-input-must-not-open.dat', str(first)], work)
    stage('missing_input_check', result.get('missing_input_check'), {'status': 0, 'stdout': '', 'stderr': ''})
    stage('missing_input_run', result.get('missing_input_run'), {'status': 1, 'stdout': '', 'stderr': str(first) + ':0:0: Cannot open explicit input file: missing-input-must-not-open.dat\n'})
    return errors
