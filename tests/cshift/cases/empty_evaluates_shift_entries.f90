program p
implicit none
integer::a(0,2),b(0,2)
a=0
b=cshift(a,[shift(),0],1)
print *, "PASS"
contains
integer function shift() result(r)
error stop "SHIFT entry evaluated"
end function
end program
