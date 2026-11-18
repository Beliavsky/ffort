! SPDX-License-Identifier: MIT
module elemental_math
    implicit none
contains
    elemental integer function affine(x, scale, shift) result(y)
        integer, intent(in) :: x, scale, shift
        y = x * scale + shift
    end function
end module
program elemental_demo
    use elemental_math
    implicit none
    integer :: a(2, 3), i, j
    do j = 1, 3
        do i = 1, 2
            a(i, j) = i + 2 * (j - 1)
        end do
    end do
    print *, affine(3, 2, 1)
    print *, affine(shift=1, x=a, scale=2)
    a(:, 2:3) = affine(a(:, 1:2), 10, 0)
    print *, a
end program
