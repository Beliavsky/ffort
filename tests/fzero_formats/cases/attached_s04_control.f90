program control
  implicit none
  integer :: i, j, n
  character(len=8) :: grade
  n = 0
  outer: do i = 1, 10
     inner: do j = 1, 10
        if (j > i) cycle outer
        if (i*j > 30) exit outer
        n = n + 1
     end do inner
  end do outer
  print '(3i5)', n, i, j
  do i = 10, 1
     print *, 'never'
  end do
  print '(i0)', i
  do i = 1, 10, 3
  end do
  print '(i0)', i
  do i = 5, -5, -4
     print '(i0)', i
  end do
  do i = 0, 100, 25
     select case (i)
     case (:10)
        grade = 'low'
     case (11:50)
        grade = 'mid'
     case (75, 100)
        grade = 'top'
     case default
        grade = 'other'
     end select
     print '(i4,1x,a)', i, trim(grade)
  end do
  if (n > 100) then
     print *, 'big'
  else if (n > 10) then
     print *, 'medium'
  else
     print *, 'small'
  end if
end program control
