#!/usr/bin/env python3
import unittest
from run_accuracy import assess,ulp
class AccuracyContracts(unittest.TestCase):
 def row(self,reference):return [dict(index=1,x_hex='0x1.0p+0',reference=reference)]
 def test_unit(self):self.assertTrue(assess('1 1.0\n',self.row('1'),8)[0]['passed'])
 def test_zero_cannot_match_subnormal(self):self.assertFalse(assess('1 0.0\n',self.row('3.138408733985445e-309'),8)[0]['passed'])
 def test_nonfinite_rejected(self):
  for x in ['NaN','Infinity','-Infinity']:self.assertFalse(assess('1 '+x+'\n',self.row('1'),8)[0]['passed'])
 def test_outside_ulp_bound(self):self.assertFalse(assess('1 1.00000000000001\n',self.row('1'),8)[0]['passed'])
 def test_record_count(self):
  with self.assertRaises(AssertionError):assess('',self.row('1'),8)
 def test_record_index(self):
  with self.assertRaises(AssertionError):assess('2 1.0',self.row('1'),8)
 def test_binary32_subnormal_ulp(self):self.assertEqual(ulp(1e-40,4),2.0**-149)
if __name__=='__main__':unittest.main()
