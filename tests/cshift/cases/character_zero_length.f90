program p
implicit none
character(len=0)::a(2,3),b(2,3)
a=''
b=cshift(a,[1,0,-1],1)
if(len(b)/=0.or.size(b)/=6) error stop 1
print *, "PASS"
end program
