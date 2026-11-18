program p
implicit none
real(8)::a(2,2),v(4)
integer::shape_values(2),ord(2)
logical::mask(2,2)
print *,kind(reshape(pack(a,mask),shape_values,order=ord))
print *,kind(pack(reshape(v,shape_values,order=ord),mask))
end program
