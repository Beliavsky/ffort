program sum_squares
    implicit none
    integer :: i, total
    total = 0
    do i = 1, 10
        total = total + i**2
    end do
    print *, 'Sum of squares:', total
    print *, 'Final loop value:', i
end program sum_squares
