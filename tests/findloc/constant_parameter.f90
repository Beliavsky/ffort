program p
implicit none
integer,parameter::a(4)=[1,2,3,2]
integer(8),parameter::i=findloc(a,2,1,kind=8,back=.true.)
integer,parameter::v(1)=findloc(a,2)
print *,i,v,kind(i)
end program
