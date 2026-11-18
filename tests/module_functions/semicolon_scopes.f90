module m; contains; function f(x) result(y)
integer,intent(in) :: x; integer :: y; y=x+1
end function f; function g(x) result(y)
integer,intent(in) :: x; integer :: y; y=f(x)*2
end function g; end module m
program main; use m; integer :: x,y; x=7; y=8
print *, f(2),g(2),x,y; end program main
