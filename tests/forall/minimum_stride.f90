program p
implicit none
integer(8)::i
integer::a(2)
a=0
forall(i=0_8:(-9223372036854775807_8-1_8):(-9223372036854775807_8-1_8)) &
 a(int(i/(-9223372036854775807_8-1_8))+1)=7
print *,a
end program
