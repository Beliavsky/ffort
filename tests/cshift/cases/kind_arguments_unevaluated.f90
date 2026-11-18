program p
implicit none
integer::k
integer::a(3)
k=kind(cshift(make(),shift=shift(),dim=dim()))
if(k/=8) error stop 1
k=kind(cshift(a,shift(),dim()))
if(k/=4) error stop 2
print *, "PASS"
contains
function make() result(r)
integer(8)::r(3)
error stop "KIND evaluated ARRAY"
end function
integer function shift() result(r)
error stop "KIND evaluated SHIFT"
end function
integer function dim() result(r)
error stop "KIND evaluated DIM"
end function
end program
