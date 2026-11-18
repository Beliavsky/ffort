! Explicit-shape matrices, rank-two dummies and column-major output.
module matrix_operations
    implicit none
contains
    subroutine multiply(left, right, product_values)
        real(kind=8), intent(in) :: left(:,:), right(:,:)
        real(kind=8), intent(out) :: product_values(:,:)
        integer :: i, j, k
        if (size(left,2) /= size(right,1)) error stop 'inner matrix dimensions differ'
        if (size(product_values,1) /= size(left,1)) error stop 'wrong result rows'
        if (size(product_values,2) /= size(right,2)) error stop 'wrong result columns'
        product_values = 0.0d0
        do j = 1, size(right,2)
            do i = 1, size(left,1)
                do k = 1, size(left,2)
                    product_values(i,j) = product_values(i,j) + left(i,k)*right(k,j)
                end do
            end do
        end do
    end subroutine multiply
end module matrix_operations

program matrix_example
    use matrix_operations, only: multiply
    implicit none
    real(kind=8) :: aa(2,3), bb(3,2), cc(2,2)
    integer :: i, j
    do j = 1, 3
        do i = 1, 2
            aa(i,j) = i + 2*(j-1)
        end do
    end do
    do j = 1, 2
        do i = 1, 3
            bb(i,j) = 6 + i + 3*(j-1)
        end do
    end do
    call multiply(aa, bb, cc)
    print *, cc
    print *, size(cc), size(cc,1), size(cc,2)
end program matrix_example
