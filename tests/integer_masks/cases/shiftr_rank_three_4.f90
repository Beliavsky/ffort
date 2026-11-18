program p
implicit none
integer(4)::a(2,1,2)
integer::n(2,1,2)
a=-1_4
n=reshape([0,1,31,32],[2,1,2])
print *,shiftr(a,n)
end program
