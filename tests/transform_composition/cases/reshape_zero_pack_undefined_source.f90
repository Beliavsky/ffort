program p
implicit none
integer::a(5),z(0,3)
character(2)::c(3),empty(0)
z=reshape(pack(a,.false.),[0,3],order=[2,1])
empty=reshape(pack(c,.false.),[0])
print *,size(z),size(empty),size(pack(reshape(a,[0,3]),.true.))
print *,size(reshape(pack(a,.false.),[3,0],pad=pack(a,.false.),order=[2,1]))
end program
