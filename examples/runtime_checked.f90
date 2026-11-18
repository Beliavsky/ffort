program runtime_checked
    implicit none
    integer :: x
    x = 2147483647
    x = x + 1
    print *, x
end program runtime_checked
