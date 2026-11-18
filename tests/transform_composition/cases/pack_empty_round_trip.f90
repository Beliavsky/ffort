program main
implicit none
integer::a(2)=[1,2]
print *,size(reshape(pack(a,.false.),[0,4])),size(pack(reshape(a,[0,4]),.true.))
end program
