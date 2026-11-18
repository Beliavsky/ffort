program p
implicit none
logical::a(2,2)
a(1,:)=[.true.,.false.]
a(2,:)=[.false.,.false.]
print *,parity(dim=1_8,mask=a),parity(mask=a,dim=2_8)
end program
