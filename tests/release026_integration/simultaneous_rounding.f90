program p
implicit none
integer::i,a(4)=[1,2,3,4],idx(4)=[4,3,2,1]
forall(i=1:4)
 a(idx(i))=nint(dble(a(i))**2)
 a(i)=ceiling(dble(a(i))/2.0_8)
end forall
print *,a
end program
