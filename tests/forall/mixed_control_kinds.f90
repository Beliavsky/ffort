program p
implicit none
integer(8)::i
integer::a(3)
forall(i=1:3_8:1) a(int(i))=int(i)
print *,a
end program
