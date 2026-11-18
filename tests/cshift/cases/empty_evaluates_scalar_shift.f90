program p
implicit none
integer::a(0),b(0)
a=0
b=cshift(a,shift())
print *, "PASS"
contains
integer function shift() result(r)
error stop "SHIFT evaluated"
end function
end program
