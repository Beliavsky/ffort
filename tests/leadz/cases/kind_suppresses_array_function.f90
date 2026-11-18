program p
implicit none
print *,kind(leadz(f()))
contains
function f() result(a)
integer(8)::a(3)
error stop 91
a=[0_8,1_8,-1_8]
end function
end program
