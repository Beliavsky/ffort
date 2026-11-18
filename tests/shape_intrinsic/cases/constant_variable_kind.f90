program p
implicit none
integer::a(3,2)
integer,parameter::k=8
integer(kind=8),parameter::s(2)=shape(source=a,kind=k)
print *,s,kind(s)
end program
