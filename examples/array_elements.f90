! Rank-one explicit-shape arrays: lower bounds, indexing and conversions.
program array_elements
    implicit none
    integer :: squares(-2:2), i, total
    real :: scaled(5)
    logical :: positive(-2:2)
    total = 0
    do i = -2, 2
        squares(i) = i * i
        scaled(i + 3) = real(squares(i)) / 2.0
        positive(i) = i > 0
        total = total + squares(i)
    end do
    print *, 'sum of squares:', total
    print *, 'edge elements:', squares(-2), squares(2)
    print *, 'scaled:', scaled(1), scaled(3), scaled(5)
    print *, 'positive:', positive(-2), positive(0), positive(2)
end program array_elements
