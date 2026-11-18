program p
implicit none
integer::i
logical::a(4)
a=[.true.,.false.,.false.,.true.]
forall(i=1:4) a(i)=.not.a(5-i)
print *,a
end program
