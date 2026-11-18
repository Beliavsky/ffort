program p
implicit none
integer(8)::a(2,1,2)
integer::n(2,1,2)
a=-1_8
n(1,1,1)=0
n(2,1,1)=1
n(1,1,2)=63
n(2,1,2)=64
print *,shiftr(a,n)
end program
