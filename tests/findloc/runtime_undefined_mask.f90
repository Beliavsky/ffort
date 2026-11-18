program p
implicit none
logical::m(2)
print *,findloc([1,2],1,mask=m)
end program
