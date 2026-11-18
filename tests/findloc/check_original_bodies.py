from pathlib import Path
import re
ROOT=Path(__file__).resolve().parent
def check():
 source=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_text()
 body=re.search(r'^pure subroutine compress\(.*?^end subroutine compress',source,re.M|re.S).group()
 assert body in (ROOT/'utility_compress_declaration_blocked.f90').read_text()
 algorithm=body[body.index('n = size(words)'):body.index('end subroutine compress')]
 assert algorithm in (ROOT/'utility_compress_algorithm.f90').read_text()
 print('PASS: original compress executable algorithm preserved; full original declaration separately accepted')
if __name__=='__main__':check()
