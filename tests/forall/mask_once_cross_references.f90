program p
implicit none
integer::i,a(4)
a=[1,2,3,4]
forall(i=1:4,a(5-i)<3) a(i)=9
print *,a
end program
