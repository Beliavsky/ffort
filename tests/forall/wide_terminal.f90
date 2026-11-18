program p
implicit none
integer(8)::i,j
integer::a(2)
j=9223372036854775807_8
forall(i=j:j) a(1)=5
forall(i=(-9223372036854775807_8-1_8):(-9223372036854775807_8-1_8):-1_8) a(2)=6
print *,a
end program
