program main
implicit none
integer::a(1)=[1]
print *,size(pack(reshape(a,[0,2]),reshape([.true.],[0,3])))
end program
