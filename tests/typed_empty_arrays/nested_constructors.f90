program p
implicit none
integer::a(3)
real(8)::b(2)
a=[[integer::],1,[integer::],2,3]
b=[[real(8)::],-0.0d0,1.5d0]
if(any(a/=[1,2,3])) error stop 1
print *, b
print *, 'PASS' 
end program
