program p
implicit none
integer::i
real(8)::a(4)
integer::b(4)
a=[1.2_8,2.8_8,3.6_8,4.0_8]
forall(i=1:4) b(i)=a(5-i)
print *,b
end program
