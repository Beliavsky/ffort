program p
implicit none
integer::a(3),value,dim
logical::mask(3),back
print *,kind(findloc(a,value,dim=dim,mask=mask,back=back,kind=8))
end program
