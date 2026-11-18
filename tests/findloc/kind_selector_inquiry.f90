program p
integer::a(3),v
integer,parameter::k=kind(findloc([1,2],2))
print *,findloc([2,1,2],2,kind=k),kind(findloc(a,v))
end program
