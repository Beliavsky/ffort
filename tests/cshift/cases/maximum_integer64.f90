program p
implicit none
integer(8)::s(2)
integer::a(3,2)
a=reshape([1,2,3,4,5,6],[3,2])
s=[9223372036854775807_8,9223372036854775807_8-1_8]
if(any(cshift(a,s,1_8)/=reshape([2,3,1,4,5,6],[3,2]))) error stop 1
if(any(cshift([1,2,3],9223372036854775807_8)/=[2,3,1])) error stop 2
print *, "PASS"
end program
