program p
implicit none
write(*,'(i0)')kind(eoshift(f(),1))
contains
function f() result(a)
real(8)::a(2)
stop 9
end function
end program
