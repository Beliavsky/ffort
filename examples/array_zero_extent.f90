! Explicit-shape bounds are constant expressions. Empty arrays are valid.
program array_zero_extent
    implicit none
    integer :: empty(3:1), values(-abs(2):2**2), i, total
    total = 0
    do i = -2, 4
        values(i) = i
        total = total + values(i)
    end do
    print *, total
end program array_zero_extent
