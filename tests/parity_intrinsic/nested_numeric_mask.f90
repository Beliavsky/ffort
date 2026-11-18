program p
implicit none
integer::a(2,3)
a(1,:)=[1,2,3]
a(2,:)=[2,3,4]
print *,parity(sum(a,dim=1)>4),parity(parity(a>2,dim=1))
end program
