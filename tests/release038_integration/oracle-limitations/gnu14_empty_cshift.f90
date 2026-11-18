program main
implicit none
integer::a(0,3),b(0,3),c(2,0),d(2,0)
b=cshift(a,[1,-1,0],1)
d=cshift(c,[1,-1],2)
if(size(b)/=0.or.size(d)/=0)error stop 1
end program
