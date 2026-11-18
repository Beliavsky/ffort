program p
implicit none
logical::a(0)
print *,parity(a),parity(a,dim=1)
end program
