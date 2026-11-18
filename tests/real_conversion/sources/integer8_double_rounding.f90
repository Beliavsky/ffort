program p
implicit none
integer(8)::j(2)=[4611686293305294849_8,-4611686293305294849_8]
real(4)::a(2)
real(4),parameter::pos=real(4611686293305294849_8,4)
real(4),parameter::neg=real(-4611686293305294849_8,4)
a=real(j,4)
print *,a,pos,neg
print *,all(real(j,4)/=real(real(j,8),4))
print *,real(j(1),4)==pos,real(j(2))==neg
print *,pos==4611686568183201792.0_4,neg==-4611686568183201792.0_4
end program p
