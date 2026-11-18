program p
implicit none
integer::i
integer,allocatable::a(:)
forall(i=1:2) a(i)=i
end program
