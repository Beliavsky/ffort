program p
implicit none
logical::a(2,3)
a(1,:)=[.true.,.false.,.true.]
a(2,:)=[.false.,.true.,.true.]
print *,parity(a),parity(a,dim=1),parity(a,dim=2)
end program
