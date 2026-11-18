program main
implicit none
integer::a(2,2)
a=reshape([1,2,3,4],[2,2])
print *,pack(a,reshape([.false.,.true.,.false.,.true.],[2,2],order=[2,1]))
end program
