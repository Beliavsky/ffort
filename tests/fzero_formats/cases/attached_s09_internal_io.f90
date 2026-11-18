program iio
  implicit none
  character(len=40) :: buf
  integer :: i, j
  real(8) :: d
  write(buf, '(a,i3.3,a,f6.2)') 'id=', 7, ' val=', 3.14159d0
  print '(a)', trim(buf)
  buf = '  42   -17   2.5d0'
  read(buf, *) i, j, d
  print '(i0,1x,i0,1x,f6.3)', i, j, d
  write(buf, '(3(i0,:,","))') 1, 22, 333
  print '(a)', trim(buf)
  print '(2(a,i0,2x))', 'a=', 1, 'b=', 2
  print '(5x,a,t2,a)', 'xyz', 'Q'
  print '("literal",1x,i0)', 5
end program iio
