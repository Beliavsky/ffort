program p
implicit none
integer::a(0),b(0)
a=0
b=cshift(a,1,dim())
print *, "PASS"
contains
integer function dim() result(r)
error stop "DIM evaluated"
end function
end program
