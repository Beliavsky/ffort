module perm_mod
  implicit none
  integer :: count = 0
contains
  recursive subroutine permute(a, k)
    integer, intent(inout) :: a(:)
    integer, intent(in) :: k
    integer :: i, t
    if (k == size(a)) then
       count = count + 1
       if (count <= 6) print '(4i2)', a
       return
    end if
    do i = k, size(a)
       t = a(k); a(k) = a(i); a(i) = t
       call permute(a, k+1)
       t = a(k); a(k) = a(i); a(i) = t
    end do
  end subroutine permute
  recursive integer function ackermann(m, n) result(r)
    integer, intent(in) :: m, n
    if (m == 0) then
       r = n + 1
    else if (n == 0) then
       r = ackermann(m-1, 1)
    else
       r = ackermann(m-1, ackermann(m, n-1))
    end if
  end function ackermann
end module perm_mod
program rec_arrays
  use perm_mod
  implicit none
  integer :: a(4) = [1,2,3,4]
  call permute(a, 1)
  print '(i0)', count
  print '(i0)', ackermann(2, 3)
end program rec_arrays
