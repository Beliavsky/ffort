program p
implicit none
integer,parameter::k=4
integer(k),parameter::v=maskl(3_8,k)
print *,v,kind(v)
end program
