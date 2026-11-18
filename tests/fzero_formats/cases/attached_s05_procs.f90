module m
  implicit none
  integer, parameter :: dp = kind(1.d0)
contains
  subroutine swap(a, b)
    integer, intent(inout) :: a, b
    integer :: t
    t = a; a = b; b = t
  end subroutine swap
  pure function cumsum(x) result(y)
    real(dp), intent(in) :: x(:)
    real(dp) :: y(size(x))
    integer :: i
    y(1) = x(1)
    do i = 2, size(x)
       y(i) = y(i-1) + x(i)
    end do
  end function cumsum
  elemental real(dp) function sq(x)
    real(dp), intent(in) :: x
    sq = x*x
  end function sq
  subroutine stats(x, mean, var)
    real(dp), intent(in) :: x(:)
    real(dp), intent(out) :: mean
    real(dp), intent(out), optional :: var
    mean = sum(x)/size(x)
    if (present(var)) var = sum((x-mean)**2)/(size(x)-1)
  end subroutine stats
  subroutine fill(a)
    integer, intent(out) :: a(:,:)
    integer :: i, j
    do j = 1, size(a,2)
       do i = 1, size(a,1)
          a(i,j) = i*j
       end do
    end do
  end subroutine fill
end module m
program procs
  use m
  implicit none
  integer :: x, y, g(2,3), v(6)
  real(dp) :: d(5), mu, s2
  x = 1; y = 2
  call swap(x, y)
  print '(2i3)', x, y
  v = [1,2,3,4,5,6]
  call swap(v(1), v(6))
  print '(6i3)', v
  d = [1,2,3,4,5]
  print '(5f6.1)', cumsum(d)
  print '(5f6.1)', sq(d)
  call stats(d, mu, s2)
  print '(2f8.3)', mu, s2
  call stats(d, mu)
  print '(f8.3)', mu
  call fill(g)
  print '(3i3)', g
  call fill(g(:,2:3))
  print '(3i3)', g
end program procs
