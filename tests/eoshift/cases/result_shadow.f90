program p
implicit none
write(*,'(i0)')f()
contains
integer function f() result(eoshift)
eoshift=8
end function
end program
