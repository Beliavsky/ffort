program p
implicit none
integer::i,a(3)
a=0
if(.true.) forall(i=1:3) a(i)=i
print *,a
end program
