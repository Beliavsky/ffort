program p
implicit none
integer(8)::a(2,2)
integer::n(2,2)
a=-1_8
n=reshape([0,1,63,64],[2,2])
print *,shiftr(a,n)
end program
