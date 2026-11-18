! SPDX-License-Identifier: MIT
program array_intrinsics
    implicit none
    integer :: a(2,3), b(3,2), weights(3), i, j
    logical :: selected(2,3)
    do j=1,3
        weights(j)=j
        do i=1,2
            a(i,j)=i+3*(j-1)
            b(j,i)=a(i,j)
        end do
    end do
    selected=a>4
    print *, 'total, product, min, max: ', sum(a), product(weights), minval(a), maxval(a)
    print *, 'column totals: ', sum(a,1)
    print *, 'row totals: ', sum(a,2)
    print *, 'selected total: ', sum(a,selected)
    print *, 'weighted rows: ', matmul(a,weights)
    print *, 'Gram matrix: ', matmul(a,b)
    print *, 'weight norm squared: ', dot_product(weights,weights)
end program array_intrinsics
