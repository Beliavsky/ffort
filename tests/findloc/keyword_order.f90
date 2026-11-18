program p
implicit none
integer::a(3)=[2,1,2]
print *,findloc(back=.true.,kind=8,mask=a>0,dim=1,value=2,array=a)
print *,findloc(value=2,array=a,kind=8),findloc(a,2,.true.,back=.true.)
end program
