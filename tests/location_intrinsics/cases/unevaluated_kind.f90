program p
implicit none
real(8)::a(2,2)
integer::d
logical::m(2,2),b
print *,kind(minloc(a,dim=d,mask=m,kind=8,back=b))
end program
