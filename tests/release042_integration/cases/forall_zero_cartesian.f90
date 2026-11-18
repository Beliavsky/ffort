program p
implicit none
integer,allocatable::a(:,:)
integer::i,j,rhs
forall(i=1:0,j=1:1000000) a(i,j)=rhs
forall(i=1:1000000,j=1:0) a(i,j)=rhs
print '(a)','ok'
end program
