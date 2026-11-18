from pathlib import Path
import re
ROOT=Path(__file__).resolve().parent
def check():
 source=(ROOT.parent/'utilities_slices/source/xutilities.f90').read_text()
 for name,file in [('lag_good_data_vec','utility_lag_good_data'),('lag_good_data_vec','utility_madev_good'),('madev_good','utility_madev_good')]:
  test=(ROOT/(file+'.f90')).read_text()
  pattern=r'^subroutine '+name+r'\(.*?^end subroutine '+name
  assert re.search(pattern,source,re.M|re.S).group()==re.search(pattern,test,re.M|re.S).group(),name
 statement='   where (.not. xma_good) xma = default_value'
 assert statement in source and statement in (ROOT/'utility_madev_good.f90').read_text()
 print('PASS: original lag_good_data_vec and madev_good preserved verbatim (newline normalization only)')
if __name__=='__main__':check()
