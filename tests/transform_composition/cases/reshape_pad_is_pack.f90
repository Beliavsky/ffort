program p
implicit none
integer::a(2,3),v(4)
a=reshape([1,2],[2,3],pad=pack([7,8,9,10],[.true.,.false.,.true.,.false.]),order=[2,1])
print *,a
v=pack(reshape([1,2,3,4],[2,2]),reshape([.false.,.true.,.false.,.true.],[2,2]), &
vector=reshape([90,91,92,93],[4]))
print *,v
end program
