program p
implicit none
integer::k
real::x(-2:0,5:6)
k=kind(ubound(x,dim=next(),kind=8))
if(k/=8)error stop 1
contains
integer function next()result(d)
integer::z
d=z
end function
end program
