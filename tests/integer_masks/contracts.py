"""Fail-closed MASKL/MASKR/SHIFTR record, stage and diagnostic contracts (no tolerance)."""
import re
TOKEN = re.compile(r'(?:0|-?[1-9][0-9]*|T|F)\Z')
CRASH = re.compile(r'backtrace|segmentation fault|sig(?:segv|abrt|bus|fpe|ill|kill|term)|core dumped|addresssanitizer|undefinedbehaviorsanitizer|program received signal|error termination|floating.point exception', re.I)

def output_matches(case, output):
    if not isinstance(output, str): return False
    if case.get('byte_exact'): return output == case['expected_stdout']
    records = case['expected_records']
    if not records: return output == ''
    if not output.endswith('\n') or '\r' in output or '\x00' in output: return False
    lines = output[:-1].split('\n')
    if len(lines) != len(records): return False
    for line, expected in zip(lines, records):
        if re.search(r'[^ 0-9TF-]', line): return False
        tokens = line.split(' ')
        tokens = [token for token in tokens if token]
        if not tokens or any(not TOKEN.fullmatch(token) for token in tokens): return False
        if tokens != expected: return False
    return True

def stage_errors(case, phase, record, source):
    errors = []
    code = (1 if case['stage']=='check' else 0) if phase=='check' else {'check':1,'runtime':2,'success':0}[case['stage']]
    if record.get('returncode') != code: errors.append('exact exit status')
    if record.get('timeout') is not False: errors.append('timeout state')
    out, err = record.get('stdout'), record.get('stderr')
    if not isinstance(out,str) or not isinstance(err,str): return errors+['nontext output']
    if CRASH.search(out+'\n'+err): errors.append('host crash marker')
    if phase=='check':
        if out != '': errors.append('check stdout not empty')
    elif not output_matches(case,out): errors.append('exact output records')
    if code == 0:
        if err != '': errors.append('successful stderr not empty')
    else:
        diagnostic = case['diagnostics'][phase]
        expected = f"{source}:{diagnostic['line']}:{diagnostic['column']}: {diagnostic['message']}\n"
        if err != expected: errors.append('exact source/phase diagnostic')
    return errors
