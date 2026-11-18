program main
implicit none
integer::n
n=f()
contains
integer function f() result(v)
write(*,*)1
v=1
end function
end program
