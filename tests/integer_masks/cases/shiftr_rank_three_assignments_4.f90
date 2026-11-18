program p
implicit none
integer(4)::a(2,1,2)
integer::n(2,1,2)
a=-1_4
n(1,1,1)=0
n(2,1,1)=1
n(1,1,2)=31
n(2,1,2)=32
print *,shiftr(a,n)
end program
