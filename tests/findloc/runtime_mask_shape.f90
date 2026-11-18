program p
implicit none
integer::n=1,a(2)=[1,2]
logical::m(2)=.true.
print *,findloc(a,1,mask=m(:n))
end program
