program p
implicit none
logical,parameter::a(2)=[.true.,.false.]
logical,parameter::b(2)=(.not.a).or.a
print *,b
end program p
