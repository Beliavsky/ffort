program p
implicit none
integer,parameter::i=1
integer::a(2)
forall(i=1:2) a(i)=3
end program
