program p
implicit none
logical::a(3,0)
print *,parity(a),size(parity(a,dim=1)),parity(a,dim=2)
end program
