program whole_arrays
    implicit none
    integer, parameter :: n=4
    integer :: a(0:n-1), b(-2:1), i
    real :: scaled(n)
    logical :: selected(n)
    do i=0,n-1
        a(i)=i+1
    end do
    b=a**2
    a=a+a(0)
    scaled=real(b)/2.0
    selected=(a>3).and.(b<16)
    print *, a
    print *, b
    print *, scaled
    print *, selected
    print *, max(b,5)
end program whole_arrays
