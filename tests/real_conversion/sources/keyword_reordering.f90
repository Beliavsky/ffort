program p
implicit none
integer,parameter::dp=kind(1.0d0)
print *,real(a=17),real(a=17,kind=dp),real(kind=dp,a=17)
print *,kind(real(kind=dp,a=1.0)),kind(real(1d0,kind=4))
end program p
