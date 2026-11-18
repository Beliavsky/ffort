from pathlib import Path
import tempfile,subprocess,shutil
R=Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix='fixed-length-replay-') as tmp:
 t=Path(tmp);(t/'cases').mkdir();shutil.copytree(R/'source',t/'source');shutil.copy2(R/'generate_cases.py',t/'generate_cases.py');subprocess.run(['python3',t/'generate_cases.py'],check=True,capture_output=True)
 files=[Path('manifest.json')]+[p.relative_to(R) for p in sorted((R/'cases').glob('*.f90'))]
 for p in files:assert (R/p).read_bytes()==(t/p).read_bytes(),p
 print(len(files),'files replay exactly')
