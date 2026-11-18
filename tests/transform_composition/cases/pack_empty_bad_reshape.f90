program main
implicit none
integer::a(1)=[1]
print *,size(pack(reshape(a,[-1,2]),.false.))
end program
