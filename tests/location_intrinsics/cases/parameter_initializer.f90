program p
implicit none
integer,parameter::loc(2)=minloc(reshape([4,3,2,1],[2,2]))
integer,parameter::q=maxloc([1,2,3],1)
print *,loc,q
end program
