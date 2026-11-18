program arith
  implicit none
  integer :: i
  integer(8) :: big
  real :: r
  real(8) :: d
  print '(6i6)', -7/2, mod(-7,2), modulo(-7,2), 7/(-2), mod(7,-2), modulo(7,-2)
  print '(4i6)', 2**10, (-2)**3, 2**(-1), 0**0
  print '(6i5)', nint(2.5), nint(-2.5), nint(3.5), floor(-1.5), ceiling(-1.5), int(-1.9)
  big = huge(1)
  big = big + 1
  print '(i0)', big
  print '(i0)', huge(big)
  r = 1.0/3.0
  d = 1.0d0/3.0d0
  print '(f12.9,1x,f20.17)', r, d
  print '(es15.7,1x,es24.16)', r, d
  print '(e12.4,1x,g12.4,1x,g12.4)', 1234.5678, 1234.5678, 0.00012345
  print '(f8.3)', 2.0**0.5
  print '(f10.4)', -0.00004
  print '(i5.3,1x,i3)', 7, -5
  print '(l3,l3)', .true., 1 > 2
  print '(f6.2)', 12345.0
  print '(i2)', 123
  d = 0
  do i = 1, 10
     d = d + 0.1d0
  end do
  print '(f22.18)', d
  print '(2f10.4)', abs(-3.5), sign(2.0, -1.0)
  print '(3f10.5)', exp(1.0d0), log(10.0d0), sqrt(2.0d0)
  print '(3f10.5)', atan2(1.0, -1.0), asin(1.0), acos(0.0)
  print '(i0,1x,i0)', max(3, 7, -1), min(3, 7, -1)
  print '(f10.3)', max(1.5, 2.0)
end program arith
