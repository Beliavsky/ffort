program p
implicit none
integer::a(3),i,x
integer,allocatable::b(:)
a=7
i=21
forall(i=3:1) a(i)=x
forall(i=1:3,.false.) b(i)=x
print *,a,i
end program
