module m
integer::i
end module
program p
use m
integer::a(3)
forall(i=1:3) a(i)=i
end program
