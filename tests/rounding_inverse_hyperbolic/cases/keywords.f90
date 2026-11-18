program p
implicit none
integer,parameter::dp=8
print *,aint(kind=dp,a=-2.75),anint(kind=4,a=-2.5d0)
print *,asinh(x=2.0d0),acosh(x=2.0)
print *,kind(aint(2.1d0)),kind(aint(2.1d0,4)),kind(anint(2.1,8)),kind(asinh(2d0)),kind(acosh(2.0))
end program
