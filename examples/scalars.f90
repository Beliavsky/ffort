program scalars
    implicit none
    integer :: n = 7
    real :: ratio
    logical :: positive
    ratio = real(n) / 4.0
    positive = ratio > 0.0 .and. n /= 0
    if (positive) then
        print *, 'Ratio:', ratio, 'Truncated:', int(ratio)
    else
        print *, 'Not positive'
    end if
    print *, abs(-8), min(3, 1, 2), max(3, 1, 2), mod(7, 3)
end program scalars
