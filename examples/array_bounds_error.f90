! Intentionally fails at runtime. Valid indices are -1, 0, and 1.
program array_bounds_error
    implicit none
    integer :: values(-1:1), i
    i = 2
    values(i) = 10
end program array_bounds_error
