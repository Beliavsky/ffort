program main
implicit none
integer::a(6)=[-1,2,3,-4,5,-6]
print *,count(reshape(pack(a,a>0),[3,1])>0),pack(reshape(a,[2,3]),reshape(a,[2,3])>0)
end program
