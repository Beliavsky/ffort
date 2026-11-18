program main
implicit none
integer::a(2)=[1,2]
print *,lbound(pack(a,.true.),1),ubound(pack(a,.true.),1)
print *,lbound(pack(a,.false.),1),ubound(pack(a,.false.),1)
end program
