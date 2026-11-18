program arrays2
  implicit none
  integer :: a(10), b(3,4), i, j
  integer, allocatable :: c(:), m(:,:)
  a = [(i, i=1,10)]
  print '(10i4)', a(10:1:-1)
  print '(10i4)', a(::3)
  a(2:9) = a(1:8)
  print '(10i4)', a
  a = [(i, i=1,10)]
  a(1:8) = a(3:10)
  print '(10i4)', a
  do j = 1, 4
     do i = 1, 3
        b(i,j) = 10*i + j
     end do
  end do
  print '(4i4)', transpose(b)
  print '(4i4)', sum(b, dim=1)
  print '(3i4)', sum(b, dim=2)
  print '(3i4)', maxval(b, dim=2)
  print '(2i4)', maxloc(b)
  print '(4i4)', b(2,:)
  print '(i4)', product([1,2,3,4,5])
  allocate(c(0:4))
  c = 5
  print '(3i4)', lbound(c), ubound(c), size(c)
  c = [1,2]
  print '(3i4)', lbound(c), ubound(c), size(c)
  m = reshape([(i, i=1,6)], [3,2])
  print '(2i4)', shape(m)
  print '(6i4)', m
  print '(6i4)', cshift([1,2,3,4,5,6], 2)
  print '(6i4)', eoshift([1,2,3,4,5,6], -2)
  print '(i4)', dot_product([1,2,3], [4,5,6])
  print '(3i4)', merge([1,2,3], [7,8,9], [.true., .false., .true.])
  print '(i4)', findloc([5,3,7,3], 3, back=.true.)
  print '(4i4)', spread_test()
contains
  function spread_test() result(r)
    integer :: r(4)
    r = [4,3,2,1]
  end function spread_test
end program arrays2
