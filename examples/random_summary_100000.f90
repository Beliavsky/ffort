program main
implicit none
integer, parameter :: dp = kind(1.0d0), n = 10**5
real(kind=dp) :: x(n)
call random_number(x)
print*,minval(x),maxval(x),sum(x)/n
end program main
