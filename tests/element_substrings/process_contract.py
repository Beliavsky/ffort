"""Process/output helpers copied unchanged from reviewed INQUIRE R5-exact."""
import os,subprocess,base64,hashlib
from pathlib import Path
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

