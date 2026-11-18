program chars
  implicit none
  character(len=10) :: a, b
  character(len=5) :: arr(3)
  character(len=:), allocatable :: s
  integer :: i
  a = 'abc'
  b = 'abc       '
  print '(l2)', a == b
  print '(l2,l2)', 'abc' < 'abd', 'B' > 'a'
  print '(a,a)', '[', a, ']'
  print '(a)', '[' // a(2:3) // ']'
  arr = ['one  ', 'two  ', 'three']
  print '(3a)', arr
  print '(a)', arr(3)(2:4)  ! array-element substring
  s = ''
  do i = 1, 5
     s = s // achar(iachar('a') + i - 1)
  end do
  print '(a,1x,i0)', s, len(s)
  print '(i0)', index('hello world', 'o', back=.true.)
  print '(a)', trim(adjustl('   left'))
  print '(a5,a)', 'abcdefgh', '|'
  print '(a10,a)', 'ab', '|'
  a = 'Hello'
  b = a
  b(1:1) = 'J'
  print '(a,1x,a)', trim(a), trim(b)
  print '(a)', repeat('-', 20)
  print '(i0)', len_trim('   ')
  print '(a)', char(72) // char(105)
  print *, 'it''s', "say ""hi"""
end program chars
