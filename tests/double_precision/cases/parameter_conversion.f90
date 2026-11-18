program p
implicit none
doubleprecision,parameter::from_default=5.2,exact=5.2d0
double precision :: undefined
if(from_default==exact)error stop 1
print *,kind(from_default),from_default,exact,kind(undefined)
end program
