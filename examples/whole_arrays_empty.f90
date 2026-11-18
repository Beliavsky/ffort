program whole_arrays_empty
    implicit none
    integer :: a(0), b(7:6)
    a=4
    b=a+2
    print *, 'empty:', b, ':done'
end program whole_arrays_empty
