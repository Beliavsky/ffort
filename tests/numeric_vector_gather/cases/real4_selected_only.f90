program p
implicit none
real(4)::a(4),b(3)
a(2)=9
b=a([2,2,2])
if(any(b/=9))error stop 1
print '(i0)',1
end program
