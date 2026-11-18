program p
implicit none
logical,parameter::flag(2)=isnan([1d0,2d0])
print *,flag
end program
