program p
implicit none
logical,parameter::a(3)=[.true.,.true.,.false.]
logical,parameter::x=parity(a,dim=1)
print *,x
end program
