program p
implicit none
integer(8)::a(3),b(3)
a=[-huge(0_8)-1_8,huge(0_8),9007199254740993_8]
b=a([3,1,2])
if(any(b/=[9007199254740993_8,-huge(0_8)-1_8,huge(0_8)]))error stop 1
print '(i0)',1
end program
