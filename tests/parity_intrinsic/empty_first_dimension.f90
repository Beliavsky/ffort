program p
implicit none
logical::a(0,3)
print *,parity(a),parity(a,dim=1),size(parity(a,dim=2))
end program
