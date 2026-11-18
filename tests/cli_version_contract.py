"""Exact current-run CLI identity; independent of historical evidence versions."""
import re
from pathlib import Path

_VERSION = r'(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)'

def expected_version(value):
    """An explicit released X.Y.Z version, never an arbitrary prefix."""
    if not isinstance(value, str) or re.fullmatch(_VERSION, value) is None:
        raise ValueError('expected version must be an exact X.Y.Z release version')
    return value

def read_project_version(path):
    """Read the unique top-level FPM release version without a new dependency."""
    text = Path(path).read_text(encoding='utf-8')
    top = re.split(r'(?m)^[ \t]*\[', text, maxsplit=1)[0]
    values = re.findall(r'(?m)^[ \t]*version[ \t]*=[ \t]*"([^"\r\n]+)"[ \t]*(?:#[^\r\n]*)?\r?$', top)
    if len(values) != 1:
        raise ValueError('fpm.toml must declare one top-level release version')
    return expected_version(values[0])

def version_errors(record, wanted):
    """Require a clean single banner with the explicitly requested version."""
    wanted = expected_version(wanted)
    errors = []
    if type(record.get('returncode')) is not int or record['returncode'] != 0:
        errors.append('version command exit status')
    if record.get('timeout') is not False:
        errors.append('version command timeout state')
    if record.get('stderr') != '':
        errors.append('version command stderr must be empty')
    out = record.get('stdout')
    banner = r'fortfront-interpreter ' + re.escape(wanted) + r'; FortFront [0-9a-f]{7,40} \+ documented local patches\r?\n'
    if not isinstance(out, str) or re.fullmatch(banner, out) is None:
        errors.append('exact expected release banner')
    return errors
